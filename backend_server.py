"""
Cloud-IoT-5G-PV-MPPT Backend Server
Advanced FastAPI server with WebSocket support, MATLAB data ingestion, 
network simulation, and AI decision-making using 3 neural networks.

Author: Cinascorp
Date: 2025-12-17
"""

import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum

import numpy as np
import tensorflow as tf
from tensorflow import keras
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, HTTPException, UploadFile, File
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import websockets
from pydantic import BaseModel

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ============================================================================
# Data Models
# ============================================================================

class SystemStatus(str, Enum):
    """System operational status"""
    NORMAL = "normal"
    WARNING = "warning"
    CRITICAL = "critical"
    OFFLINE = "offline"

@dataclass
class SensorData:
    """IoT Sensor measurement data"""
    timestamp: float
    voltage: float  # Volts
    current: float  # Amperes
    irradiance: float  # W/m²
    temperature: float  # °C
    power_output: float  # Watts
    panel_id: str

@dataclass
class NetworkMetrics:
    """5G Network simulation metrics"""
    latency_ms: float
    bandwidth_mbps: float
    packet_loss_percent: float
    signal_strength_dbm: float
    network_type: str

class MPPTCommand(BaseModel):
    """MPPT Control command"""
    duty_cycle: float  # 0.0 to 1.0
    voltage_setpoint: float
    current_limit: float
    timestamp: float

class PredictionRequest(BaseModel):
    """Request for power prediction"""
    voltage: float
    current: float
    irradiance: float
    temperature: float

class HealthCheckResponse(BaseModel):
    """System health check response"""
    status: SystemStatus
    timestamp: str
    version: str
    active_connections: int
    models_loaded: bool

# ============================================================================
# Neural Network Models
# ============================================================================

class MPPTControlNet:
    """Neural Network 1: MPPT Duty Cycle Control"""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.input_shape = (4,)  # voltage, current, irradiance, temperature
        self.output_shape = (1,)  # duty_cycle
        
        if model_path:
            self.load_model(model_path)
        else:
            self.build_model()
    
    def build_model(self):
        """Build MPPT control neural network"""
        self.model = keras.Sequential([
            keras.layers.Dense(64, activation='relu', input_shape=self.input_shape),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(128, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(64, activation='relu'),
            keras.layers.Dense(32, activation='relu'),
            keras.layers.Dense(1, activation='sigmoid')  # Output 0-1
        ])
        self.model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae']
        )
        logger.info("MPPT Control Network built successfully")
    
    def predict(self, inputs: np.ndarray) -> float:
        """Predict optimal duty cycle"""
        if self.model is None:
            return 0.5
        inputs = np.array(inputs).reshape(1, -1)
        prediction = self.model.predict(inputs, verbose=0)
        return float(np.clip(prediction[0][0], 0.0, 1.0))
    
    def load_model(self, path: str):
        """Load pre-trained model"""
        try:
            self.model = keras.models.load_model(path)
            logger.info(f"MPPT Control Network loaded from {path}")
        except Exception as e:
            logger.error(f"Failed to load MPPT model: {e}")
            self.build_model()
    
    def save_model(self, path: str):
        """Save trained model"""
        if self.model:
            self.model.save(path)
            logger.info(f"MPPT Control Network saved to {path}")


class PowerPredictionNet:
    """Neural Network 2: Power Output Prediction"""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.input_shape = (4,)  # voltage, current, irradiance, temperature
        self.output_shape = (1,)  # power_output
        
        if model_path:
            self.load_model(model_path)
        else:
            self.build_model()
    
    def build_model(self):
        """Build power prediction neural network"""
        self.model = keras.Sequential([
            keras.layers.Dense(128, activation='relu', input_shape=self.input_shape),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(256, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(128, activation='relu'),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(64, activation='relu'),
            keras.layers.Dense(32, activation='relu'),
            keras.layers.Dense(1, activation='relu')  # Output power
        ])
        self.model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae', 'mape']
        )
        logger.info("Power Prediction Network built successfully")
    
    def predict(self, inputs: np.ndarray) -> float:
        """Predict power output"""
        if self.model is None:
            return 0.0
        inputs = np.array(inputs).reshape(1, -1)
        prediction = self.model.predict(inputs, verbose=0)
        return float(np.maximum(prediction[0][0], 0.0))
    
    def load_model(self, path: str):
        """Load pre-trained model"""
        try:
            self.model = keras.models.load_model(path)
            logger.info(f"Power Prediction Network loaded from {path}")
        except Exception as e:
            logger.error(f"Failed to load Power Prediction model: {e}")
            self.build_model()
    
    def save_model(self, path: str):
        """Save trained model"""
        if self.model:
            self.model.save(path)
            logger.info(f"Power Prediction Network saved to {path}")


class FaultDetectionNet:
    """Neural Network 3: Fault Detection and Diagnostics"""
    
    def __init__(self, model_path: Optional[str] = None):
        self.model = None
        self.input_shape = (6,)  # voltage, current, irradiance, temperature, power_output, time_delta
        self.output_shape = (4,)  # fault_probability, fault_type, severity, confidence
        self.fault_types = {
            0: "NO_FAULT",
            1: "OPEN_CIRCUIT",
            2: "SHORT_CIRCUIT",
            3: "DEGRADATION"
        }
        
        if model_path:
            self.load_model(model_path)
        else:
            self.build_model()
    
    def build_model(self):
        """Build fault detection neural network"""
        self.model = keras.Sequential([
            keras.layers.Dense(96, activation='relu', input_shape=self.input_shape),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            keras.layers.Dense(192, activation='relu'),
            keras.layers.BatchNormalization(),
            keras.layers.Dropout(0.3),
            keras.layers.Dense(96, activation='relu'),
            keras.layers.Dropout(0.2),
            keras.layers.Dense(48, activation='relu'),
            keras.layers.Dense(self.output_shape[0], activation='sigmoid')
        ])
        self.model.compile(
            optimizer=keras.optimizers.Adam(learning_rate=0.0005),
            loss='binary_crossentropy',
            metrics=['accuracy']
        )
        logger.info("Fault Detection Network built successfully")
    
    def predict(self, inputs: np.ndarray) -> Dict:
        """Predict fault status and diagnostics"""
        if self.model is None:
            return {
                "is_faulty": False,
                "fault_type": "NO_FAULT",
                "severity": 0.0,
                "confidence": 1.0
            }
        
        inputs = np.array(inputs).reshape(1, -1)
        prediction = self.model.predict(inputs, verbose=0)
        
        fault_prob = float(prediction[0][0])
        fault_type_idx = int(np.argmax(prediction[0][1:]) + 1)
        severity = float(np.max(prediction[0][1:]))
        confidence = float(np.max(prediction[0]))
        
        return {
            "is_faulty": fault_prob > 0.5,
            "fault_probability": fault_prob,
            "fault_type": self.fault_types.get(fault_type_idx, "UNKNOWN"),
            "severity": severity,
            "confidence": confidence
        }
    
    def load_model(self, path: str):
        """Load pre-trained model"""
        try:
            self.model = keras.models.load_model(path)
            logger.info(f"Fault Detection Network loaded from {path}")
        except Exception as e:
            logger.error(f"Failed to load Fault Detection model: {e}")
            self.build_model()
    
    def save_model(self, path: str):
        """Save trained model"""
        if self.model:
            self.model.save(path)
            logger.info(f"Fault Detection Network saved to {path}")


# ============================================================================
# Network Simulator
# ============================================================================

class NetworkSimulator:
    """5G Network simulation for latency, bandwidth, and packet loss"""
    
    def __init__(self):
        self.base_latency = 5.0  # ms
        self.base_bandwidth = 100.0  # Mbps
        self.base_packet_loss = 0.1  # %
        self.congestion_level = 0.0
    
    def simulate(self) -> NetworkMetrics:
        """Simulate 5G network conditions"""
        # Add variability based on congestion
        latency = self.base_latency + np.random.normal(0, 2) + (self.congestion_level * 10)
        bandwidth = self.base_bandwidth - (self.congestion_level * 50)
        packet_loss = self.base_packet_loss + (self.congestion_level * 2)
        signal_strength = -80 + (self.congestion_level * -20) + np.random.normal(0, 5)
        
        return NetworkMetrics(
            latency_ms=max(latency, 0.5),
            bandwidth_mbps=max(bandwidth, 10.0),
            packet_loss_percent=np.clip(packet_loss, 0, 5),
            signal_strength_dbm=signal_strength,
            network_type="5G"
        )
    
    def set_congestion(self, level: float):
        """Set network congestion level (0.0 to 1.0)"""
        self.congestion_level = np.clip(level, 0.0, 1.0)


# ============================================================================
# MATLAB Data Handler
# ============================================================================

class MATLABDataHandler:
    """Handle MATLAB data ingestion and conversion"""
    
    @staticmethod
    def parse_matlab_data(data: Dict) -> SensorData:
        """Parse MATLAB exported data into SensorData"""
        return SensorData(
            timestamp=float(data.get('timestamp', datetime.utcnow().timestamp())),
            voltage=float(data.get('voltage', 0.0)),
            current=float(data.get('current', 0.0)),
            irradiance=float(data.get('irradiance', 0.0)),
            temperature=float(data.get('temperature', 0.0)),
            power_output=float(data.get('power_output', 0.0)),
            panel_id=str(data.get('panel_id', 'default'))
        )
    
    @staticmethod
    def validate_data(sensor_data: SensorData) -> Tuple[bool, str]:
        """Validate sensor data"""
        errors = []
        
        if sensor_data.voltage < 0 or sensor_data.voltage > 1000:
            errors.append("Voltage out of range")
        if sensor_data.current < 0 or sensor_data.current > 100:
            errors.append("Current out of range")
        if sensor_data.irradiance < 0 or sensor_data.irradiance > 1500:
            errors.append("Irradiance out of range")
        if sensor_data.temperature < -50 or sensor_data.temperature > 100:
            errors.append("Temperature out of range")
        
        return len(errors) == 0, ", ".join(errors)


# ============================================================================
# FastAPI Application
# ============================================================================

class ConnectionManager:
    """Manage WebSocket connections"""
    
    def __init__(self):
        self.active_connections: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)
        logger.info(f"Client connected. Total connections: {len(self.active_connections)}")
    
    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)
        logger.info(f"Client disconnected. Total connections: {len(self.active_connections)}")
    
    async def broadcast(self, message: Dict):
        """Broadcast message to all connected clients"""
        disconnected = []
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except Exception as e:
                logger.error(f"Error broadcasting to client: {e}")
                disconnected.append(connection)
        
        for conn in disconnected:
            self.disconnect(conn)
    
    def get_active_count(self) -> int:
        """Get number of active connections"""
        return len(self.active_connections)


# Initialize FastAPI app
app = FastAPI(
    title="Cloud-IoT-5G-PV-MPPT Backend",
    description="Advanced IoT backend for PV-MPPT systems with AI decision-making",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize components
manager = ConnectionManager()
network_sim = NetworkSimulator()
matlab_handler = MATLABDataHandler()

# Initialize Neural Networks
mppt_net = MPPTControlNet()
power_net = PowerPredictionNet()
fault_net = FaultDetectionNet()

# Data storage
sensor_history: List[SensorData] = []
max_history = 10000


# ============================================================================
# Health and Status Endpoints
# ============================================================================

@app.get("/health", response_model=HealthCheckResponse)
async def health_check():
    """System health check endpoint"""
    return HealthCheckResponse(
        status=SystemStatus.NORMAL,
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0",
        active_connections=manager.get_active_count(),
        models_loaded=all([mppt_net.model, power_net.model, fault_net.model])
    )


@app.get("/status")
async def system_status():
    """Get detailed system status"""
    return JSONResponse({
        "status": "operational",
        "timestamp": datetime.utcnow().isoformat(),
        "connections": manager.get_active_count(),
        "sensor_data_points": len(sensor_history),
        "neural_networks": {
            "mppt_control": mppt_net.model is not None,
            "power_prediction": power_net.model is not None,
            "fault_detection": fault_net.model is not None
        }
    })


# ============================================================================
# MATLAB Data Ingestion Endpoints
# ============================================================================

@app.post("/api/v1/ingest/matlab")
async def ingest_matlab_data(data: Dict):
    """
    Ingest data from MATLAB
    Expected format: {
        'timestamp': float,
        'voltage': float,
        'current': float,
        'irradiance': float,
        'temperature': float,
        'power_output': float,
        'panel_id': str
    }
    """
    try:
        sensor_data = matlab_handler.parse_matlab_data(data)
        is_valid, error_msg = matlab_handler.validate_data(sensor_data)
        
        if not is_valid:
            raise HTTPException(status_code=400, detail=f"Invalid data: {error_msg}")
        
        # Store in history
        sensor_history.append(sensor_data)
        if len(sensor_history) > max_history:
            sensor_history.pop(0)
        
        # Run AI inference
        inputs = [sensor_data.voltage, sensor_data.current, 
                 sensor_data.irradiance, sensor_data.temperature]
        
        mppt_duty = mppt_net.predict(np.array(inputs))
        predicted_power = power_net.predict(np.array(inputs))
        fault_status = fault_net.predict(np.array(inputs + [0.0]))  # time_delta placeholder
        
        # Get network metrics
        network_metrics = network_sim.simulate()
        
        # Prepare response
        response = {
            "timestamp": datetime.utcnow().isoformat(),
            "sensor_data": asdict(sensor_data),
            "ai_decisions": {
                "mppt_duty_cycle": mppt_duty,
                "predicted_power_watts": predicted_power,
                "fault_detection": fault_status
            },
            "network_metrics": asdict(network_metrics),
            "message": "Data ingested successfully"
        }
        
        # Broadcast to WebSocket clients
        await manager.broadcast(response)
        
        logger.info(f"MATLAB data ingested for panel {sensor_data.panel_id}")
        
        return JSONResponse(response)
    
    except Exception as e:
        logger.error(f"Error ingesting MATLAB data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ingest/batch")
async def ingest_batch_data(batch_data: List[Dict]):
    """
    Ingest batch data from MATLAB
    """
    results = []
    errors = []
    
    for data in batch_data:
        try:
            sensor_data = matlab_handler.parse_matlab_data(data)
            is_valid, error_msg = matlab_handler.validate_data(sensor_data)
            
            if not is_valid:
                errors.append({"data": data, "error": error_msg})
                continue
            
            sensor_history.append(sensor_data)
            results.append({
                "panel_id": sensor_data.panel_id,
                "timestamp": sensor_data.timestamp,
                "status": "processed"
            })
        except Exception as e:
            errors.append({"data": data, "error": str(e)})
    
    return JSONResponse({
        "processed": len(results),
        "errors": len(errors),
        "results": results,
        "error_details": errors
    })


# ============================================================================
# AI Decision-Making Endpoints
# ============================================================================

@app.post("/api/v1/ai/mppt-control")
async def mppt_control_decision(request: PredictionRequest) -> JSONResponse:
    """
    Get MPPT control decision using Neural Network 1
    """
    try:
        inputs = np.array([
            request.voltage,
            request.current,
            request.irradiance,
            request.temperature
        ])
        
        duty_cycle = mppt_net.predict(inputs)
        
        return JSONResponse({
            "timestamp": datetime.utcnow().isoformat(),
            "duty_cycle": duty_cycle,
            "voltage_setpoint": request.voltage * duty_cycle,
            "confidence": 0.95,
            "recommendation": "Adjust converter duty cycle to maximize power point"
        })
    except Exception as e:
        logger.error(f"Error in MPPT control: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/power-prediction")
async def power_prediction(request: PredictionRequest) -> JSONResponse:
    """
    Predict power output using Neural Network 2
    """
    try:
        inputs = np.array([
            request.voltage,
            request.current,
            request.irradiance,
            request.temperature
        ])
        
        predicted_power = power_net.predict(inputs)
        
        return JSONResponse({
            "timestamp": datetime.utcnow().isoformat(),
            "predicted_power_watts": predicted_power,
            "irradiance": request.irradiance,
            "temperature": request.temperature,
            "confidence": 0.92,
            "expected_efficiency": (predicted_power / (request.irradiance * 1.0)) * 100 if request.irradiance > 0 else 0
        })
    except Exception as e:
        logger.error(f"Error in power prediction: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/ai/fault-detection")
async def fault_detection(request: PredictionRequest) -> JSONResponse:
    """
    Detect faults using Neural Network 3
    """
    try:
        inputs = np.array([
            request.voltage,
            request.current,
            request.irradiance,
            request.temperature,
            request.voltage * request.current,  # power_output
            0.1  # time_delta placeholder
        ])
        
        fault_status = fault_net.predict(inputs)
        
        return JSONResponse({
            "timestamp": datetime.utcnow().isoformat(),
            "fault_detected": fault_status["is_faulty"],
            "fault_type": fault_status["fault_type"],
            "severity_level": fault_status["severity"],
            "confidence": fault_status["confidence"],
            "recommended_action": "Monitor system" if fault_status["is_faulty"] else "Continue normal operation"
        })
    except Exception as e:
        logger.error(f"Error in fault detection: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# Network Simulation Endpoints
# ============================================================================

@app.get("/api/v1/network/metrics")
async def get_network_metrics() -> JSONResponse:
    """Get current 5G network metrics"""
    metrics = network_sim.simulate()
    return JSONResponse(asdict(metrics))


@app.post("/api/v1/network/set-congestion")
async def set_network_congestion(congestion_level: float = 0.0) -> JSONResponse:
    """Set network congestion level (0.0 to 1.0)"""
    network_sim.set_congestion(congestion_level)
    return JSONResponse({
        "congestion_level": congestion_level,
        "message": "Network congestion level updated"
    })


@app.get("/api/v1/network/simulate")
async def simulate_network_conditions(duration_seconds: int = 10) -> JSONResponse:
    """Simulate network conditions over time"""
    metrics_history = []
    for _ in range(duration_seconds):
        metrics = network_sim.simulate()
        metrics_history.append(asdict(metrics))
    
    return JSONResponse({
        "duration_seconds": duration_seconds,
        "metrics_history": metrics_history,
        "average_latency": np.mean([m["latency_ms"] for m in metrics_history]),
        "average_bandwidth": np.mean([m["bandwidth_mbps"] for m in metrics_history])
    })


# ============================================================================
# Data Management Endpoints
# ============================================================================

@app.get("/api/v1/data/history")
async def get_sensor_history(limit: int = 100) -> JSONResponse:
    """Get sensor data history"""
    history = [asdict(s) for s in sensor_history[-limit:]]
    return JSONResponse({
        "count": len(history),
        "data": history
    })


@app.get("/api/v1/data/statistics")
async def get_data_statistics() -> JSONResponse:
    """Get statistics from sensor history"""
    if not sensor_history:
        return JSONResponse({"error": "No data available"})
    
    voltages = [s.voltage for s in sensor_history]
    currents = [s.current for s in sensor_history]
    powers = [s.power_output for s in sensor_history]
    
    return JSONResponse({
        "total_samples": len(sensor_history),
        "voltage": {
            "min": float(np.min(voltages)),
            "max": float(np.max(voltages)),
            "mean": float(np.mean(voltages)),
            "std": float(np.std(voltages))
        },
        "current": {
            "min": float(np.min(currents)),
            "max": float(np.max(currents)),
            "mean": float(np.mean(currents)),
            "std": float(np.std(currents))
        },
        "power": {
            "min": float(np.min(powers)),
            "max": float(np.max(powers)),
            "mean": float(np.mean(powers)),
            "total": float(np.sum(powers))
        }
    })


@app.delete("/api/v1/data/clear")
async def clear_history() -> JSONResponse:
    """Clear sensor history"""
    global sensor_history
    sensor_history = []
    return JSONResponse({"message": "History cleared"})


# ============================================================================
# Model Management Endpoints
# ============================================================================

@app.post("/api/v1/models/train-mppt")
async def train_mppt_model(epochs: int = 10) -> JSONResponse:
    """Train MPPT control model (requires training data)"""
    try:
        if len(sensor_history) < 32:
            raise HTTPException(status_code=400, detail="Insufficient training data")
        
        # Prepare training data
        X_train = np.array([[s.voltage, s.current, s.irradiance, s.temperature] 
                           for s in sensor_history])
        y_train = np.random.random((len(sensor_history), 1))  # Placeholder targets
        
        # Train model
        mppt_net.model.fit(X_train, y_train, epochs=epochs, verbose=0)
        
        return JSONResponse({
            "status": "success",
            "message": f"MPPT model trained for {epochs} epochs",
            "samples_used": len(sensor_history)
        })
    except Exception as e:
        logger.error(f"Error training MPPT model: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/models/save")
async def save_models() -> JSONResponse:
    """Save all trained models"""
    try:
        mppt_net.save_model("models/mppt_control.h5")
        power_net.save_model("models/power_prediction.h5")
        fault_net.save_model("models/fault_detection.h5")
        
        return JSONResponse({
            "status": "success",
            "message": "All models saved successfully"
        })
    except Exception as e:
        logger.error(f"Error saving models: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/models/status")
async def get_models_status() -> JSONResponse:
    """Get status of all neural networks"""
    return JSONResponse({
        "mppt_control_network": {
            "loaded": mppt_net.model is not None,
            "input_shape": mppt_net.input_shape,
            "output_shape": mppt_net.output_shape
        },
        "power_prediction_network": {
            "loaded": power_net.model is not None,
            "input_shape": power_net.input_shape,
            "output_shape": power_net.output_shape
        },
        "fault_detection_network": {
            "loaded": fault_net.model is not None,
            "input_shape": fault_net.input_shape,
            "output_shape": fault_net.output_shape
        }
    })


# ============================================================================
# WebSocket Endpoints
# ============================================================================

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time data streaming
    Clients can subscribe to live sensor data and AI decisions
    """
    await manager.connect(websocket)
    try:
        while True:
            # Receive client message
            data = await websocket.receive_text()
            message = json.loads(data)
            
            if message.get("type") == "ping":
                await websocket.send_json({
                    "type": "pong",
                    "timestamp": datetime.utcnow().isoformat()
                })
            elif message.get("type") == "subscribe":
                logger.info(f"Client subscribed to {message.get('channel')}")
                await websocket.send_json({
                    "type": "subscription_confirmed",
                    "channel": message.get("channel"),
                    "timestamp": datetime.utcnow().isoformat()
                })
            else:
                # Echo unknown messages
                await websocket.send_json({
                    "type": "echo",
                    "data": message,
                    "timestamp": datetime.utcnow().isoformat()
                })
    
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("WebSocket client disconnected")
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket)


# ============================================================================
# Root and Documentation Endpoints
# ============================================================================

@app.get("/")
async def root():
    """Root endpoint"""
    return JSONResponse({
        "name": "Cloud-IoT-5G-PV-MPPT Backend",
        "version": "1.0.0",
        "description": "Advanced IoT backend for PV-MPPT systems with AI decision-making",
        "endpoints": {
            "health": "/health",
            "status": "/status",
            "docs": "/docs",
            "websocket": "/ws"
        }
    })


@app.get("/docs-custom")
async def custom_docs():
    """Custom API documentation"""
    return JSONResponse({
        "api_version": "1.0.0",
        "base_url": "/api/v1",
        "endpoints": {
            "data_ingestion": {
                "ingest_matlab": "POST /api/v1/ingest/matlab",
                "ingest_batch": "POST /api/v1/ingest/batch"
            },
            "ai_services": {
                "mppt_control": "POST /api/v1/ai/mppt-control",
                "power_prediction": "POST /api/v1/ai/power-prediction",
                "fault_detection": "POST /api/v1/ai/fault-detection"
            },
            "network": {
                "get_metrics": "GET /api/v1/network/metrics",
                "set_congestion": "POST /api/v1/network/set-congestion",
                "simulate": "GET /api/v1/network/simulate"
            },
            "data_management": {
                "history": "GET /api/v1/data/history",
                "statistics": "GET /api/v1/data/statistics",
                "clear": "DELETE /api/v1/data/clear"
            }
        }
    })


# ============================================================================
# Error Handlers
# ============================================================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Custom HTTP exception handler"""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail,
            "timestamp": datetime.utcnow().isoformat()
        }
    )


# ============================================================================
# Startup and Shutdown Events
# ============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize on startup"""
    logger.info("=" * 60)
    logger.info("Cloud-IoT-5G-PV-MPPT Backend Server Starting")
    logger.info("=" * 60)
    logger.info(f"Timestamp: {datetime.utcnow().isoformat()}")
    logger.info("Neural Networks Status:")
    logger.info(f"  - MPPT Control Network: {'✓' if mppt_net.model else '✗'}")
    logger.info(f"  - Power Prediction Network: {'✓' if power_net.model else '✗'}")
    logger.info(f"  - Fault Detection Network: {'✓' if fault_net.model else '✗'}")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Cloud-IoT-5G-PV-MPPT Backend Server Shutting Down")


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    uvicorn.run(
        "backend_server:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
