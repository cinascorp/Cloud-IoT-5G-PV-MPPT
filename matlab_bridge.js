/**
 * MATLAB Bridge Server
 * 
 * Bridges MATLAB and FastAPI backend with:
 * - MATLAB data ingestion
 * - WebSocket real-time streaming
 * - Network simulation
 * - Fault detection
 * - AI decision making
 * - Comprehensive error handling and logging
 * 
 * @author cinascorp
 * @date 2025-12-17
 */

const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { EventEmitter } = require('events');
const net = require('net');

// Configuration
const CONFIG = {
  PORT: process.env.PORT || 3000,
  FASTAPI_URL: process.env.FASTAPI_URL || 'http://localhost:8000',
  MATLAB_PORT: process.env.MATLAB_PORT || 5000,
  LOG_DIR: process.env.LOG_DIR || './logs',
  LOG_LEVEL: process.env.LOG_LEVEL || 'info',
  ENABLE_NETWORK_SIMULATION: process.env.ENABLE_NETWORK_SIMULATION === 'true' || true,
  WEBSOCKET_PING_INTERVAL: 30000,
  DATA_BUFFER_SIZE: 1000,
  FAULT_DETECTION_THRESHOLD: 0.85,
};

// Logger
class Logger {
  constructor(logDir = CONFIG.LOG_DIR, level = CONFIG.LOG_LEVEL) {
    this.logDir = logDir;
    this.level = level;
    this.levels = { error: 0, warn: 1, info: 2, debug: 3 };
    this.currentLevel = this.levels[level];
    
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
  }

  getTimestamp() {
    return new Date().toISOString();
  }

  write(level, message, data = {}) {
    if (this.levels[level] > this.currentLevel) return;

    const logEntry = {
      timestamp: this.getTimestamp(),
      level: level.toUpperCase(),
      message,
      data,
      pid: process.pid,
    };

    const logLine = JSON.stringify(logEntry);
    console.log(logLine);

    const logFile = path.join(this.logDir, `${level}.log`);
    fs.appendFileSync(logFile, logLine + '\n', { encoding: 'utf8' });
  }

  error(message, data) {
    this.write('error', message, data);
  }

  warn(message, data) {
    this.write('warn', message, data);
  }

  info(message, data) {
    this.write('info', message, data);
  }

  debug(message, data) {
    this.write('debug', message, data);
  }
}

const logger = new Logger();

// Data Buffer for streaming
class DataBuffer extends EventEmitter {
  constructor(maxSize = CONFIG.DATA_BUFFER_SIZE) {
    super();
    this.buffer = [];
    this.maxSize = maxSize;
  }

  add(data) {
    this.buffer.push({
      ...data,
      timestamp: new Date().toISOString(),
    });

    if (this.buffer.length > this.maxSize) {
      this.buffer.shift();
    }

    this.emit('data', data);
  }

  getLatest(count = 10) {
    return this.buffer.slice(-count);
  }

  clear() {
    this.buffer = [];
  }
}

// Network Simulator
class NetworkSimulator {
  constructor(enabled = CONFIG.ENABLE_NETWORK_SIMULATION) {
    this.enabled = enabled;
    this.latencyMs = 0;
    this.packetLossRate = 0;
    this.bandwidthLimitMbps = 100;
  }

  async simulateNetwork(data) {
    if (!this.enabled) return data;

    // Random latency (0-100ms)
    this.latencyMs = Math.random() * 100;
    await this.delay(this.latencyMs);

    // Simulate packet loss
    this.packetLossRate = Math.random() * 0.05; // 5% max loss
    if (Math.random() < this.packetLossRate) {
      throw new Error('Simulated packet loss');
    }

    return data;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  getMetrics() {
    return {
      latencyMs: this.latencyMs,
      packetLossRate: this.packetLossRate,
      bandwidthLimitMbps: this.bandwidthLimitMbps,
    };
  }
}

// Fault Detection Engine
class FaultDetectionEngine extends EventEmitter {
  constructor(threshold = CONFIG.FAULT_DETECTION_THRESHOLD) {
    super();
    this.threshold = threshold;
    this.historicalData = [];
    this.maxHistorySize = 100;
  }

  async detectFaults(data) {
    const faults = [];

    // Voltage anomaly detection
    if (data.voltage !== undefined) {
      const voltageAnomaly = this.detectAnomaly(data.voltage, 'voltage');
      if (voltageAnomaly) faults.push(voltageAnomaly);
    }

    // Current anomaly detection
    if (data.current !== undefined) {
      const currentAnomaly = this.detectAnomaly(data.current, 'current');
      if (currentAnomaly) faults.push(currentAnomaly);
    }

    // Temperature anomaly detection
    if (data.temperature !== undefined) {
      const tempAnomaly = this.detectAnomaly(data.temperature, 'temperature');
      if (tempAnomaly) faults.push(tempAnomaly);
    }

    // Power factor detection
    if (data.powerFactor !== undefined && data.powerFactor < 0.9) {
      faults.push({
        type: 'LOW_POWER_FACTOR',
        severity: 'warning',
        value: data.powerFactor,
        threshold: 0.9,
      });
    }

    // Efficiency detection
    if (data.efficiency !== undefined && data.efficiency < this.threshold) {
      faults.push({
        type: 'LOW_EFFICIENCY',
        severity: 'warning',
        value: data.efficiency,
        threshold: this.threshold,
      });
    }

    this.historicalData.push(data);
    if (this.historicalData.length > this.maxHistorySize) {
      this.historicalData.shift();
    }

    if (faults.length > 0) {
      this.emit('fault_detected', faults);
    }

    return faults;
  }

  detectAnomaly(value, field) {
    if (this.historicalData.length < 5) return null;

    const recent = this.historicalData.slice(-5).map(d => d[field] || 0);
    const mean = recent.reduce((a, b) => a + b, 0) / recent.length;
    const stdDev = Math.sqrt(
      recent.reduce((sq, n) => sq + Math.pow(n - mean, 2), 0) / recent.length
    );

    const zScore = Math.abs((value - mean) / (stdDev || 1));

    if (zScore > 3) {
      return {
        type: `${field.toUpperCase()}_ANOMALY`,
        severity: zScore > 5 ? 'critical' : 'warning',
        value,
        zScore,
      };
    }

    return null;
  }
}

// AI Decision Maker
class AIDecisionMaker extends EventEmitter {
  constructor() {
    super();
    this.model = null;
    this.predictions = [];
  }

  async initialize(fastApiUrl) {
    try {
      const response = await axios.get(`${fastApiUrl}/ai/status`);
      this.model = response.data.model;
      logger.info('AI model initialized', { model: this.model });
    } catch (error) {
      logger.warn('AI model initialization failed', { error: error.message });
    }
  }

  async makePrediction(data) {
    try {
      const response = await axios.post(
        `${CONFIG.FASTAPI_URL}/ai/predict`,
        {
          features: {
            voltage: data.voltage,
            current: data.current,
            temperature: data.temperature,
            powerFactor: data.powerFactor,
            irradiance: data.irradiance,
          },
        }
      );

      const prediction = {
        timestamp: new Date().toISOString(),
        prediction: response.data.prediction,
        confidence: response.data.confidence,
        recommendation: response.data.recommendation,
      };

      this.predictions.push(prediction);
      if (this.predictions.length > 100) {
        this.predictions.shift();
      }

      return prediction;
    } catch (error) {
      logger.error('AI prediction failed', {
        error: error.message,
        data,
      });
      return null;
    }
  }

  async getOptimalSettings(currentState) {
    try {
      const response = await axios.post(
        `${CONFIG.FASTAPI_URL}/ai/optimize`,
        { currentState }
      );

      return response.data.optimalSettings;
    } catch (error) {
      logger.error('Optimal settings computation failed', {
        error: error.message,
      });
      return null;
    }
  }
}

// MATLAB Data Ingestion Handler
class MATLABDataHandler extends EventEmitter {
  constructor() {
    super();
    this.server = net.createServer();
    this.clients = new Set();
  }

  start(port = CONFIG.MATLAB_PORT) {
    this.server.on('connection', (socket) => {
      logger.info('MATLAB client connected', { port });
      this.clients.add(socket);

      socket.on('data', (buffer) => {
        try {
          const message = buffer.toString('utf8').trim();
          const data = JSON.parse(message);
          this.emit('matlabData', data);
        } catch (error) {
          logger.error('MATLAB data parsing error', {
            error: error.message,
            buffer: buffer.toString('utf8'),
          });
        }
      });

      socket.on('error', (error) => {
        logger.error('MATLAB client error', { error: error.message });
      });

      socket.on('end', () => {
        logger.info('MATLAB client disconnected', { port });
        this.clients.delete(socket);
      });
    });

    this.server.listen(port, '0.0.0.0', () => {
      logger.info('MATLAB server started', { port });
    });
  }

  broadcast(data) {
    this.clients.forEach((client) => {
      if (client.writable) {
        client.write(JSON.stringify(data) + '\n');
      }
    });
  }

  stop() {
    this.server.close();
    this.clients.forEach((client) => client.destroy());
  }
}

// WebSocket Manager
class WebSocketManager {
  constructor() {
    this.wss = null;
    this.clients = new Set();
    this.pingInterval = null;
  }

  initialize(server) {
    this.wss = new WebSocket.Server({ server });

    this.wss.on('connection', (ws) => {
      logger.info('WebSocket client connected', {
        clientCount: this.clients.size + 1,
      });

      this.clients.add(ws);

      ws.on('message', (message) => {
        try {
          const data = JSON.parse(message);
          this.handleMessage(ws, data);
        } catch (error) {
          logger.error('WebSocket message parsing error', {
            error: error.message,
          });
        }
      });

      ws.on('error', (error) => {
        logger.error('WebSocket error', { error: error.message });
      });

      ws.on('close', () => {
        this.clients.delete(ws);
        logger.info('WebSocket client disconnected', {
          clientCount: this.clients.size,
        });
      });

      // Send welcome message
      ws.send(
        JSON.stringify({
          type: 'connection',
          message: 'Connected to MATLAB Bridge',
          timestamp: new Date().toISOString(),
        })
      );
    });

    // Ping interval to keep connections alive
    this.pingInterval = setInterval(() => {
      this.clients.forEach((ws) => {
        if (ws.isAlive === false) {
          ws.terminate();
          this.clients.delete(ws);
        } else {
          ws.isAlive = false;
          ws.ping();
        }
      });
    }, CONFIG.WEBSOCKET_PING_INTERVAL);
  }

  handleMessage(ws, data) {
    logger.debug('WebSocket message received', { type: data.type });

    switch (data.type) {
      case 'ping':
        ws.pong();
        break;
      case 'subscribe':
        ws.subscribe = data.channel;
        ws.send(JSON.stringify({ type: 'subscribed', channel: data.channel }));
        break;
      default:
        logger.warn('Unknown WebSocket message type', { type: data.type });
    }
  }

  broadcast(data, channel = null) {
    const message = JSON.stringify(data);
    this.clients.forEach((ws) => {
      if (ws.readyState === WebSocket.OPEN) {
        if (!channel || ws.subscribe === channel || !ws.subscribe) {
          ws.send(message);
        }
      }
    });
  }

  stop() {
    if (this.pingInterval) {
      clearInterval(this.pingInterval);
    }
    this.clients.forEach((ws) => ws.close());
    if (this.wss) {
      this.wss.close();
    }
  }
}

// Main Application
class MATLABBridgeServer {
  constructor() {
    this.app = express();
    this.server = http.createServer(this.app);
    this.wsManager = new WebSocketManager();
    this.dataBuffer = new DataBuffer();
    this.networkSimulator = new NetworkSimulator();
    this.faultDetector = new FaultDetectionEngine();
    this.aiDecisionMaker = new AIDecisionMaker();
    this.matlabHandler = new MATLABDataHandler();
  }

  setupMiddleware() {
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));

    // CORS middleware
    this.app.use((req, res, next) => {
      res.header('Access-Control-Allow-Origin', '*');
      res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
      res.header('Access-Control-Allow-Headers', 'Content-Type');
      next();
    });

    // Request logging middleware
    this.app.use((req, res, next) => {
      logger.debug(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('user-agent'),
      });
      next();
    });

    // Error handling middleware
    this.app.use((err, req, res, next) => {
      logger.error('Express error', {
        error: err.message,
        stack: err.stack,
        path: req.path,
      });
      res.status(500).json({
        error: 'Internal Server Error',
        message: err.message,
        timestamp: new Date().toISOString(),
      });
    });
  }

  setupRoutes() {
    // Health check
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: {
          port: CONFIG.PORT,
          fastApiUrl: CONFIG.FASTAPI_URL,
          matlabPort: CONFIG.MATLAB_PORT,
        },
      });
    });

    // MATLAB data submission
    this.app.post('/api/matlab/data', async (req, res) => {
      try {
        const data = req.body;
        logger.debug('MATLAB data received', { data });

        // Simulate network conditions
        try {
          await this.networkSimulator.simulateNetwork(data);
        } catch (error) {
          logger.warn('Network simulation error', { error: error.message });
        }

        // Detect faults
        const faults = await this.faultDetector.detectFaults(data);

        // Make AI prediction
        const prediction = await this.aiDecisionMaker.makePrediction(data);

        // Add to buffer
        this.dataBuffer.add(data);

        // Broadcast to dashboard
        this.wsManager.broadcast({
          type: 'data',
          data,
          faults,
          prediction,
          networkMetrics: this.networkSimulator.getMetrics(),
          timestamp: new Date().toISOString(),
        });

        // Forward to FastAPI backend
        try {
          await axios.post(`${CONFIG.FASTAPI_URL}/data/ingest`, data);
        } catch (error) {
          logger.error('FastAPI data forward failed', {
            error: error.message,
          });
        }

        res.json({
          status: 'success',
          faults: faults.length,
          prediction,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        logger.error('MATLAB data submission error', {
          error: error.message,
        });
        res.status(400).json({
          status: 'error',
          message: error.message,
          timestamp: new Date().toISOString(),
        });
      }
    });

    // Get latest data
    this.app.get('/api/data/latest', (req, res) => {
      const count = parseInt(req.query.count) || 10;
      const data = this.dataBuffer.getLatest(count);
      res.json({
        data,
        count: data.length,
        timestamp: new Date().toISOString(),
      });
    });

    // Get fault history
    this.app.get('/api/faults', (req, res) => {
      const predictions = this.aiDecisionMaker.predictions;
      const faultsData = predictions.filter((p) => p.prediction === 'fault');

      res.json({
        faults: faultsData,
        count: faultsData.length,
        timestamp: new Date().toISOString(),
      });
    });

    // Get AI predictions
    this.app.get('/api/predictions', (req, res) => {
      const limit = parseInt(req.query.limit) || 20;
      const predictions = this.aiDecisionMaker.predictions.slice(-limit);

      res.json({
        predictions,
        count: predictions.length,
        timestamp: new Date().toISOString(),
      });
    });

    // Get network metrics
    this.app.get('/api/network/metrics', (req, res) => {
      res.json({
        metrics: this.networkSimulator.getMetrics(),
        timestamp: new Date().toISOString(),
      });
    });

    // Trigger optimal settings calculation
    this.app.post('/api/optimize', async (req, res) => {
      try {
        const currentState = req.body;
        const optimalSettings = await this.aiDecisionMaker.getOptimalSettings(
          currentState
        );

        res.json({
          optimalSettings,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        logger.error('Optimization error', { error: error.message });
        res.status(500).json({
          error: error.message,
          timestamp: new Date().toISOString(),
        });
      }
    });

    // Get system statistics
    this.app.get('/api/stats', (req, res) => {
      const predictions = this.aiDecisionMaker.predictions;
      const faults = predictions.filter((p) => p.prediction === 'fault').length;
      const avgConfidence =
        predictions.length > 0
          ? predictions.reduce((sum, p) => sum + (p.confidence || 0), 0) /
            predictions.length
          : 0;

      res.json({
        stats: {
          totalDataPoints: this.dataBuffer.buffer.length,
          totalPredictions: predictions.length,
          faultDetected: faults,
          averageConfidence: avgConfidence,
          activeConnections: this.wsManager.clients.size,
          matlabClients: this.matlabHandler.clients.size,
        },
        timestamp: new Date().toISOString(),
      });
    });

    // Clear data buffer
    this.app.post('/api/clear', (req, res) => {
      this.dataBuffer.clear();
      logger.info('Data buffer cleared');

      res.json({
        status: 'success',
        message: 'Data buffer cleared',
        timestamp: new Date().toISOString(),
      });
    });
  }

  setupEventListeners() {
    // Listen for MATLAB data
    this.matlabHandler.on('matlabData', async (data) => {
      logger.info('MATLAB data event', { data });
      this.dataBuffer.add(data);

      const faults = await this.faultDetector.detectFaults(data);
      const prediction = await this.aiDecisionMaker.makePrediction(data);

      this.wsManager.broadcast({
        type: 'matlab_data',
        data,
        faults,
        prediction,
        timestamp: new Date().toISOString(),
      });
    });

    // Listen for faults
    this.faultDetector.on('fault_detected', (faults) => {
      logger.warn('Faults detected', { faults });
      this.wsManager.broadcast({
        type: 'fault_alert',
        faults,
        timestamp: new Date().toISOString(),
      });
    });

    // Listen for data buffer updates
    this.dataBuffer.on('data', (data) => {
      // Periodic logging
      if (this.dataBuffer.buffer.length % 10 === 0) {
        logger.info('Data buffer updated', {
          bufferSize: this.dataBuffer.buffer.length,
        });
      }
    });
  }

  async start() {
    try {
      // Setup express middleware
      this.setupMiddleware();

      // Setup routes
      this.setupRoutes();

      // Initialize WebSocket
      this.wsManager.initialize(this.server);

      // Start MATLAB handler
      this.matlabHandler.start(CONFIG.MATLAB_PORT);

      // Initialize AI decision maker
      await this.aiDecisionMaker.initialize(CONFIG.FASTAPI_URL);

      // Setup event listeners
      this.setupEventListeners();

      // Start server
      this.server.listen(CONFIG.PORT, '0.0.0.0', () => {
        logger.info('MATLAB Bridge Server started', {
          port: CONFIG.PORT,
          fastApiUrl: CONFIG.FASTAPI_URL,
          matlabPort: CONFIG.MATLAB_PORT,
        });
      });

      // Handle process signals
      process.on('SIGTERM', () => this.stop());
      process.on('SIGINT', () => this.stop());

      return this;
    } catch (error) {
      logger.error('Server startup failed', {
        error: error.message,
        stack: error.stack,
      });
      throw error;
    }
  }

  stop() {
    logger.info('Shutting down MATLAB Bridge Server');
    this.wsManager.stop();
    this.matlabHandler.stop();
    this.server.close(() => {
      logger.info('Server stopped');
      process.exit(0);
    });

    // Force shutdown after 10 seconds
    setTimeout(() => {
      logger.error('Forced shutdown');
      process.exit(1);
    }, 10000);
  }
}

// Start server if run directly
if (require.main === module) {
  const server = new MATLABBridgeServer();
  server.start().catch((error) => {
    logger.error('Fatal error', { error: error.message });
    process.exit(1);
  });
}

module.exports = {
  MATLABBridgeServer,
  Logger,
  DataBuffer,
  NetworkSimulator,
  FaultDetectionEngine,
  AIDecisionMaker,
  MATLABDataHandler,
  WebSocketManager,
};
