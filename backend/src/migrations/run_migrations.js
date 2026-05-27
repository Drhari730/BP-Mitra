// Migration runner – executes SQL migration files in numeric order.
// Usage: node src/migrations/run_migrations.js
require('dotenv').config();

const fs = require('fs');
const path = require('path');
const { pool } = require('../config/database');
const { logger } = require('../utils/logger');

async function runMigrations() {
  const migrationsDir = path.join(__dirname, '../../migrations');
  const files = fs.readdirSync(migrationsDir)
    .filter(f => f.endsWith('.sql'))
    .sort();

  const client = await pool.connect();
  try {
    // Create tracking table if absent.
    await client.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    for (const file of files) {
      const { rowCount } = await client.query(
        'SELECT id FROM _migrations WHERE filename = $1',
        [file],
      );
      if (rowCount > 0) {
        logger.info(`Skipping already-applied migration: ${file}`);
        continue;
      }

      const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
      logger.info(`Applying migration: ${file}`);
      await client.query(sql);
      await client.query(
        'INSERT INTO _migrations (filename) VALUES ($1)',
        [file],
      );
      logger.info(`✓ Migration applied: ${file}`);
    }

    logger.info('All migrations complete.');
  } catch (err) {
    logger.error('Migration failed', { error: err.message });
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
