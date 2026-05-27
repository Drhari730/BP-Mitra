// Module 1 – Medication Tracker Controller
// Handles schedule management and adherence logging with streak analysis.
const { v4: uuidv4 } = require('uuid');
const { query, getClient } = require('../config/database');
const { logger } = require('../utils/logger');

const MedicationController = {

  // ── List all active schedules for the authenticated user ────
  async listSchedules(req, res) {
    try {
      const result = await query(
        `SELECT id, med_name, dosage_mg, frequency_hours, scheduled_time,
                drug_class, is_critical, is_active, created_at
         FROM medication_schedules
         WHERE user_id = $1 AND is_active = TRUE
         ORDER BY scheduled_time ASC`,
        [req.userId],
      );
      res.json({ schedules: result.rows });
    } catch (err) {
      logger.error('listSchedules error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch schedules.' });
    }
  },

  // ── Create a new medication schedule ────────────────────────
  async createSchedule(req, res) {
    const { med_name, dosage_mg, frequency_hours, scheduled_time, drug_class, is_critical } = req.body;

    if (!med_name || !dosage_mg || !frequency_hours || !scheduled_time) {
      return res.status(422).json({ error: 'med_name, dosage_mg, frequency_hours, scheduled_time are required.' });
    }

    try {
      const result = await query(
        `INSERT INTO medication_schedules
           (id, user_id, med_name, dosage_mg, frequency_hours, scheduled_time, drug_class, is_critical)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
         RETURNING *`,
        [
          uuidv4(), req.userId, med_name, dosage_mg,
          frequency_hours, scheduled_time,
          drug_class || 'antihypertensive',
          is_critical !== undefined ? is_critical : true,
        ],
      );
      res.status(201).json({ schedule: result.rows[0] });
    } catch (err) {
      logger.error('createSchedule error', { error: err.message });
      res.status(500).json({ error: 'Failed to create schedule.' });
    }
  },

  // ── Update existing schedule (deactivate/modify timing) ─────
  async updateSchedule(req, res) {
    const { id } = req.params;
    const { scheduled_time, dosage_mg, is_active } = req.body;

    try {
      const result = await query(
        `UPDATE medication_schedules
         SET scheduled_time  = COALESCE($1, scheduled_time),
             dosage_mg       = COALESCE($2, dosage_mg),
             is_active       = COALESCE($3, is_active)
         WHERE id = $4 AND user_id = $5
         RETURNING *`,
        [scheduled_time, dosage_mg, is_active, id, req.userId],
      );
      if (!result.rowCount) return res.status(404).json({ error: 'Schedule not found.' });
      res.json({ schedule: result.rows[0] });
    } catch (err) {
      logger.error('updateSchedule error', { error: err.message });
      res.status(500).json({ error: 'Failed to update schedule.' });
    }
  },

  // ── Soft-delete by marking inactive ─────────────────────────
  async deleteSchedule(req, res) {
    try {
      const result = await query(
        `UPDATE medication_schedules SET is_active = FALSE
         WHERE id = $1 AND user_id = $2`,
        [req.params.id, req.userId],
      );
      if (!result.rowCount) return res.status(404).json({ error: 'Schedule not found.' });
      res.json({ message: 'Schedule deactivated.' });
    } catch (err) {
      logger.error('deleteSchedule error', { error: err.message });
      res.status(500).json({ error: 'Failed to delete schedule.' });
    }
  },

  // ── Log a dose adherence event (Taken / Skipped) ─────────────
  async logAdherence(req, res) {
    const { schedule_id, status, scheduled_at } = req.body;

    if (!schedule_id || !status || !scheduled_at) {
      return res.status(422).json({ error: 'schedule_id, status, scheduled_at are required.' });
    }
    if (!['Taken', 'Skipped'].includes(status)) {
      return res.status(422).json({ error: 'status must be Taken or Skipped.' });
    }

    const loggedAt = new Date();
    const scheduledDate = new Date(scheduled_at);
    const deltaMinutes = Math.round((loggedAt - scheduledDate) / 60000);

    const client = await getClient();
    try {
      await client.query('BEGIN');

      // Verify schedule belongs to user
      const sched = await client.query(
        `SELECT id, is_critical FROM medication_schedules
         WHERE id = $1 AND user_id = $2 AND is_active = TRUE`,
        [schedule_id, req.userId],
      );
      if (!sched.rowCount) {
        await client.query('ROLLBACK');
        return res.status(404).json({ error: 'Schedule not found.' });
      }

      const logResult = await client.query(
        `INSERT INTO adherence_logs
           (id, schedule_id, user_id, scheduled_at, logged_at, status, delta_minutes)
         VALUES ($1,$2,$3,$4,$5,$6,$7)
         RETURNING *`,
        [uuidv4(), schedule_id, req.userId, scheduledDate, loggedAt, status, deltaMinutes],
      );

      await client.query('COMMIT');
      res.status(201).json({ log: logResult.rows[0] });
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error('logAdherence error', { error: err.message });
      res.status(500).json({ error: 'Failed to log adherence.' });
    } finally {
      client.release();
    }
  },

  // ── Retrieve paginated adherence log history ─────────────────
  async getAdherenceLogs(req, res) {
    const limit = Math.min(parseInt(req.query.limit || '30'), 100);
    const offset = parseInt(req.query.offset || '0');
    const scheduleId = req.query.schedule_id;

    try {
      const params = [req.userId, limit, offset];
      let whereClause = 'al.user_id = $1';
      if (scheduleId) {
        whereClause += ` AND al.schedule_id = $${params.push(scheduleId)}`;
      }

      const result = await query(
        `SELECT al.id, al.scheduled_at, al.logged_at, al.status,
                al.delta_minutes, al.escalation_sent,
                ms.med_name, ms.dosage_mg
         FROM adherence_logs al
         JOIN medication_schedules ms ON ms.id = al.schedule_id
         WHERE ${whereClause}
         ORDER BY al.scheduled_at DESC
         LIMIT $2 OFFSET $3`,
        params,
      );
      res.json({ logs: result.rows });
    } catch (err) {
      logger.error('getAdherenceLogs error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch adherence logs.' });
    }
  },

  // ── Calculate consecutive-day adherence streak (Rule C) ──────
  // Returns current streak of days with 100% Taken status.
  async getAdherenceStreak(req, res) {
    try {
      // Count days (newest first) where every scheduled dose was Taken.
      // A day "breaks" the streak if any dose is Skipped or Missed.
      const result = await query(
        `WITH daily_stats AS (
           SELECT
             scheduled_at::DATE AS log_date,
             COUNT(*) FILTER (WHERE status = 'Taken')   AS taken_count,
             COUNT(*)                                    AS total_count
           FROM adherence_logs
           WHERE user_id = $1
             AND scheduled_at >= NOW() - INTERVAL '90 days'
           GROUP BY 1
           ORDER BY 1 DESC
         ),
         perfect_days AS (
           SELECT log_date,
                  ROW_NUMBER() OVER (ORDER BY log_date DESC) AS rn
           FROM daily_stats
           WHERE taken_count = total_count
         ),
         streak_calc AS (
           -- Consecutive days = those where date - rn interval is constant
           SELECT log_date,
                  log_date - (rn * INTERVAL '1 day')::DATE AS grp
           FROM perfect_days
         )
         SELECT COUNT(*) AS streak_days
         FROM streak_calc
         WHERE grp = (SELECT grp FROM streak_calc LIMIT 1)`,
        [req.userId],
      );

      const streakDays = parseInt(result.rows[0]?.streak_days || '0');
      res.json({
        streak_days: streakDays,
        // Rule C fires at 7-day perfect streak
        seven_day_milestone_reached: streakDays >= 7,
      });
    } catch (err) {
      logger.error('getAdherenceStreak error', { error: err.message });
      res.status(500).json({ error: 'Failed to compute streak.' });
    }
  },

  // ── 7-day summary: % adherence and missed count ──────────────
  async getAdherenceSummary(req, res) {
    try {
      const result = await query(
        `SELECT
           COUNT(*) FILTER (WHERE status = 'Taken')   AS taken,
           COUNT(*) FILTER (WHERE status = 'Skipped') AS skipped,
           COUNT(*) FILTER (WHERE status = 'Missed')  AS missed,
           COUNT(*)                                    AS total
         FROM adherence_logs
         WHERE user_id = $1
           AND scheduled_at >= NOW() - INTERVAL '7 days'`,
        [req.userId],
      );

      const row = result.rows[0];
      const total = parseInt(row.total) || 0;
      const taken = parseInt(row.taken) || 0;
      const adherenceRate = total > 0 ? Math.round((taken / total) * 100) : 0;

      res.json({
        period_days: 7,
        taken,
        skipped: parseInt(row.skipped) || 0,
        missed: parseInt(row.missed) || 0,
        total,
        adherence_rate_percentage: adherenceRate,
      });
    } catch (err) {
      logger.error('getAdherenceSummary error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch summary.' });
    }
  },
};

module.exports = MedicationController;
