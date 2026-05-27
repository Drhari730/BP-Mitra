// Module 3 – Vitals Controller: BP readings storage and trend aggregation.
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { logger } = require('../utils/logger');

const VitalsController = {

  // ── Store a new BP reading (rPPG or manual cuff) ─────────────
  async createReading(req, res) {
    const { systolic_mmhg, diastolic_mmhg, pulse_bpm, source, rppg_confidence, notes, measured_at } = req.body;

    if (!systolic_mmhg || !diastolic_mmhg || !source) {
      return res.status(422).json({ error: 'systolic_mmhg, diastolic_mmhg, source are required.' });
    }
    if (!['rppg', 'manual'].includes(source)) {
      return res.status(422).json({ error: "source must be 'rppg' or 'manual'." });
    }

    try {
      const result = await query(
        `INSERT INTO bp_readings
           (id, user_id, systolic_mmhg, diastolic_mmhg, pulse_bpm, source, rppg_confidence, notes, measured_at)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         RETURNING *`,
        [
          uuidv4(), req.userId, systolic_mmhg, diastolic_mmhg,
          pulse_bpm || null, source, rppg_confidence || null,
          notes || null, measured_at ? new Date(measured_at) : new Date(),
        ],
      );
      res.status(201).json({ reading: result.rows[0] });
    } catch (err) {
      logger.error('createReading error', { error: err.message });
      res.status(500).json({ error: 'Failed to save reading.' });
    }
  },

  // ── Paginated list of readings ────────────────────────────────
  async listReadings(req, res) {
    const limit = Math.min(parseInt(req.query.limit || '50'), 200);
    const offset = parseInt(req.query.offset || '0');
    const source = req.query.source; // optional filter

    try {
      const params = [req.userId, limit, offset];
      let filter = '';
      if (source) {
        filter = ` AND source = $${params.push(source)}`;
      }

      const result = await query(
        `SELECT id, systolic_mmhg, diastolic_mmhg, pulse_bpm,
                source, rppg_confidence, notes, measured_at
         FROM bp_readings
         WHERE user_id = $1 ${filter}
         ORDER BY measured_at DESC
         LIMIT $2 OFFSET $3`,
        params,
      );
      res.json({ readings: result.rows });
    } catch (err) {
      logger.error('listReadings error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch readings.' });
    }
  },

  // ── Latest single reading for dashboard card ─────────────────
  async getLatestReading(req, res) {
    try {
      const result = await query(
        `SELECT systolic_mmhg, diastolic_mmhg, pulse_bpm, source, measured_at
         FROM bp_readings
         WHERE user_id = $1
         ORDER BY measured_at DESC
         LIMIT 1`,
        [req.userId],
      );
      if (!result.rowCount) return res.status(404).json({ error: 'No readings found.' });
      res.json({ reading: result.rows[0] });
    } catch (err) {
      logger.error('getLatestReading error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch latest reading.' });
    }
  },

  // ── Trend: daily averages for fl_chart dual-line graph ────────
  async getTrend(req, res) {
    const days = Math.min(parseInt(req.query.days || '30'), 90);

    try {
      const result = await query(
        `SELECT
           measured_at::DATE                       AS date,
           ROUND(AVG(systolic_mmhg))::INTEGER       AS avg_systolic,
           ROUND(AVG(diastolic_mmhg))::INTEGER      AS avg_diastolic,
           ROUND(AVG(pulse_bpm))::INTEGER           AS avg_pulse,
           COUNT(*)::INTEGER                        AS reading_count
         FROM bp_readings
         WHERE user_id = $1
           AND measured_at >= NOW() - ($2 || ' days')::INTERVAL
         GROUP BY 1
         ORDER BY 1 ASC`,
        [req.userId, days],
      );
      res.json({ trend: result.rows, period_days: days });
    } catch (err) {
      logger.error('getTrend error', { error: err.message });
      res.status(500).json({ error: 'Failed to compute trend.' });
    }
  },
};

module.exports = VitalsController;
