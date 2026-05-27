// Module 4 – Activity Controller: upserts daily step/calorie totals.
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { logger } = require('../utils/logger');

// Standard metabolic equivalent conversion: 1 step ≈ 0.04 kcal.
const KCAL_PER_STEP = 0.04;

const ActivityController = {

  // ── Upsert today's step/calorie log from device sync payload ─
  async syncActivity(req, res) {
    const { log_date, total_steps, epoch_data } = req.body;

    if (total_steps === undefined) {
      return res.status(422).json({ error: 'total_steps is required.' });
    }

    const date = log_date || new Date().toISOString().slice(0, 10);
    const activeKcal = parseFloat((total_steps * KCAL_PER_STEP).toFixed(2));

    try {
      const result = await query(
        `INSERT INTO activity_logs (id, user_id, log_date, total_steps, active_kcal, epoch_data)
         VALUES ($1,$2,$3,$4,$5,$6)
         ON CONFLICT (user_id, log_date)
         DO UPDATE SET
           total_steps = EXCLUDED.total_steps,
           active_kcal = EXCLUDED.active_kcal,
           epoch_data  = COALESCE(EXCLUDED.epoch_data, activity_logs.epoch_data)
         RETURNING *`,
        [uuidv4(), req.userId, date, total_steps, activeKcal, epoch_data ? JSON.stringify(epoch_data) : null],
      );
      res.json({ activity: result.rows[0] });
    } catch (err) {
      logger.error('syncActivity error', { error: err.message });
      res.status(500).json({ error: 'Failed to sync activity.' });
    }
  },

  // ── Today's step count and progress fraction (goal=8000 steps) ─
  async getTodayActivity(req, res) {
    const date = new Date().toISOString().slice(0, 10);
    const DAILY_STEP_GOAL = 8000;

    try {
      const result = await query(
        `SELECT total_steps, active_kcal FROM activity_logs
         WHERE user_id = $1 AND log_date = $2`,
        [req.userId, date],
      );

      const row = result.rows[0] || { total_steps: 0, active_kcal: 0 };
      res.json({
        date,
        total_steps: parseInt(row.total_steps) || 0,
        active_kcal: parseFloat(row.active_kcal) || 0,
        daily_goal: DAILY_STEP_GOAL,
        progress_fraction: parseFloat(
          Math.min((parseInt(row.total_steps) || 0) / DAILY_STEP_GOAL, 1).toFixed(4)
        ),
      });
    } catch (err) {
      logger.error('getTodayActivity error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch today activity.' });
    }
  },

  // ── Last N days of activity history ─────────────────────────
  async getActivityHistory(req, res) {
    const days = Math.min(parseInt(req.query.days || '30'), 90);

    try {
      const result = await query(
        `SELECT log_date, total_steps, active_kcal
         FROM activity_logs
         WHERE user_id = $1
           AND log_date >= CURRENT_DATE - ($2::INTEGER - 1)
         ORDER BY log_date ASC`,
        [req.userId, days],
      );
      res.json({ history: result.rows, period_days: days });
    } catch (err) {
      logger.error('getActivityHistory error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch activity history.' });
    }
  },
};

module.exports = ActivityController;
