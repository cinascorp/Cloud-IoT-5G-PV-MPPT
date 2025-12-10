
// Simple Node server with Express and WebSocket for telemetry and decision endpoint
// No authentication. Configure as needed for production.
const express = require('express');
const bodyParser = require('body-parser');
const http = require('http');
const WebSocket = require('ws');

const app = express();
app.use(bodyParser.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

let telemetryStore = [];

// Decision logic placeholder; replace with ANN inference if available
function scoreDecision(payload){
  const s_iot = (payload.latency_iot != null) ? Math.max(0,100 - Number(payload.latency_iot)) * 0.4 + (Number(payload.snr_iot)||0)*0.6 + (Number(payload.throughput_iot)||0)*0.8 : 0;
  const s_5g  = (payload.latency_5g != null) ? Math.max(0,100 - Number(payload.latency_5g)) * 0.4 + (Number(payload.snr_5g)||0)*0.6 + (Number(payload.throughput_5g)||0)*0.8 : 0;
  const selected = s_5g > s_iot ? '5G' : 'IoT';
  return { selected, scores: { iot: s_iot, '5g': s_5g } };
}

app.post('/api/telemetry/ingest', (req, res) => {
  const payload = req.body || {};
  payload._received = new Date().toISOString();
  telemetryStore.push(payload);
  // broadcast to websocket clients
  const msg = JSON.stringify(payload);
  wss.clients.forEach(client => {
    if(client.readyState === WebSocket.OPEN) client.send(msg);
  });
  res.json({ stored: true, len: telemetryStore.length });
});

app.post('/api/decide', (req, res) => {
  const inpt = req.body || {};
  const result = scoreDecision(inpt);
  res.json({ node: inpt.node_id || null, selected: result.selected, scores: result.scores });
});

// simple endpoints for admin actions
app.post('/admin/start', (req, res) => { res.json({ started: true }); });
app.post('/admin/stop', (req, res) => { res.json({ stopped: true }); });

wss.on('connection', (ws) => {
  console.log('ws client connected');
  ws.on('message', (msg) => {
    // no-op: server receives
  });
});

const PORT = process.env.PORT || 8000;
server.listen(PORT, () => console.log('Node server listening on', PORT));
