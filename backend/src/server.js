// ============================================================
// BP Mitra – Express Application Entry Point
// ============================================================
require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const { logger } = require('./utils/logger');
const { pool } = require('./config/database');

// Route modules
const authRoutes = require('./routes/auth.routes');
const medicationRoutes = require('./routes/medication.routes');
const dietRoutes = require('./routes/diet.routes');
const vitalsRoutes = require('./routes/vitals.routes');
const activityRoutes = require('./routes/activity.routes');
const aiRoutes = require('./routes/ai.routes');

const app = express();

// ── Security Middleware ──────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
}));

// ── Request Parsing ──────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(compression());

// ── Logging ──────────────────────────────────────────────────
app.use(morgan('combined', {
  stream: { write: (msg) => logger.http(msg.trim()) },
}));

// ── Global Rate Limiter ──────────────────────────────────────
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again after 15 minutes.' },
});
app.use(globalLimiter);

// ── Health Check ─────────────────────────────────────────────
app.get('/health', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  } catch {
    res.status(503).json({ status: 'degraded', db: 'unreachable' });
  }
});

// ── API Routes ────────────────────────────────────────────────
const API = '/api/v1';
app.use(`${API}/auth`, authRoutes);
app.use(`${API}/medications`, medicationRoutes);
app.use(`${API}/diet`, dietRoutes);
app.use(`${API}/vitals`, vitalsRoutes);
app.use(`${API}/activity`, activityRoutes);
app.use(`${API}/ai`, aiRoutes);

// ── 404 Handler ───────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Resource not found' });
});

// ── Global Error Handler ──────────────────────────────────────
app.use((err, _req, res, _next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production'
      ? 'An internal error occurred.'
      : err.message,
  });
});

// ── Server Bootstrap ─────────────────────────────────────────
const PORT = process.env.PORT || 4000;
const server = app.listen(PORT, () => {
  logger.info(`BP Mitra API listening on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received – shutting down gracefully');
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
});

module.exports = app;
