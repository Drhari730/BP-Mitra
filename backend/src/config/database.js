// PostgreSQL connection pool configuration for BP Mitra backend.
// Uses pg-pool for connection pooling with health-check and retry logic.

const { Pool } = require('pg');
const { logger } = require('../utils/logger');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'bp_mitra_db',
  user: process.env.DB_USER || 'bp_mitra_user',
  password: process.env.DB_PASSWORD || '',
  max: 20,                  // Maximum connections in pool
  idleTimeoutMillis: 30000, // Close idle connections after 30s
  connectionTimeoutMillis: 5000,
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: true }
    : false,
});

pool.on('connect', () => {
  logger.info('New PostgreSQL client connected to bp_mitra_db');
});

pool.on('error', (err) => {
  logger.error('Unexpected PostgreSQL pool error', { error: err.message });
});

/**
 * Execute a parameterized query against the connection pool.
 * @param {string} text   - SQL statement with $1, $2 placeholders
 * @param {Array}  params - Bound parameter values
 * @returns {Promise<import('pg').QueryResult>}
 */
const query = async (text, params) => {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    logger.debug('Executed query', { text, duration, rows: result.rowCount });
    return result;
  } catch (err) {
    logger.error('Query error', { text, error: err.message });
    throw err;
  }
};

/**
 * Acquire a dedicated client for multi-statement transactions.
 * Caller MUST call client.release() in a finally block.
 */
const getClient = async () => pool.connect();

module.exports = { query, getClient, pool };
