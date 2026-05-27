// Module 2 – DASH Diet Controller
// Persists meal logs and computes daily sodium totals against the 1500mg cap.
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { logger } = require('../utils/logger');

const DAILY_SODIUM_CAP_MG = 1500;

const DietController = {

  // ── Log a single food item for a meal slot ──────────────────
  async logMeal(req, res) {
    const {
      log_date, meal_slot, food_item_key, food_name,
      serving_size_g, sodium_mg, potassium_mg, magnesium_mg, calories_kcal,
    } = req.body;

    if (!meal_slot || !food_item_key || !food_name || serving_size_g === undefined) {
      return res.status(422).json({ error: 'meal_slot, food_item_key, food_name, serving_size_g are required.' });
    }

    try {
      const result = await query(
        `INSERT INTO daily_food_logs
           (id, user_id, log_date, meal_slot, food_item_key, food_name,
            serving_size_g, sodium_mg, potassium_mg, magnesium_mg, calories_kcal)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
         RETURNING *`,
        [
          uuidv4(), req.userId,
          log_date ? new Date(log_date) : new Date(),
          meal_slot, food_item_key, food_name, serving_size_g,
          sodium_mg || 0, potassium_mg || 0, magnesium_mg || 0, calories_kcal || 0,
        ],
      );
      res.status(201).json({ entry: result.rows[0] });
    } catch (err) {
      logger.error('logMeal error', { error: err.message });
      res.status(500).json({ error: 'Failed to log meal.' });
    }
  },

  // ── Fetch all entries for a given date ───────────────────────
  async getDayLog(req, res) {
    const date = req.query.date || new Date().toISOString().slice(0, 10);

    try {
      const result = await query(
        `SELECT id, meal_slot, food_item_key, food_name, serving_size_g,
                sodium_mg, potassium_mg, magnesium_mg, calories_kcal, created_at
         FROM daily_food_logs
         WHERE user_id = $1 AND log_date = $2
         ORDER BY created_at ASC`,
        [req.userId, date],
      );
      res.json({ date, entries: result.rows });
    } catch (err) {
      logger.error('getDayLog error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch day log.' });
    }
  },

  // ── Daily sodium summary with progress-bar data ──────────────
  async getDailySodiumSummary(req, res) {
    const date = req.query.date || new Date().toISOString().slice(0, 10);

    try {
      const result = await query(
        `SELECT
           COALESCE(SUM(sodium_mg), 0)::NUMERIC(8,2)    AS total_sodium_mg,
           COALESCE(SUM(potassium_mg), 0)::NUMERIC(8,2)  AS total_potassium_mg,
           COALESCE(SUM(calories_kcal), 0)::NUMERIC(8,2) AS total_calories_kcal,
           COUNT(*)::INTEGER                             AS item_count
         FROM daily_food_logs
         WHERE user_id = $1 AND log_date = $2`,
        [req.userId, date],
      );

      const row = result.rows[0];
      const totalSodium = parseFloat(row.total_sodium_mg);
      const progress = Math.min(totalSodium / DAILY_SODIUM_CAP_MG, 1.0);
      const isOverLimit = totalSodium > DAILY_SODIUM_CAP_MG;

      res.json({
        date,
        total_sodium_mg: totalSodium,
        total_potassium_mg: parseFloat(row.total_potassium_mg),
        total_calories_kcal: parseFloat(row.total_calories_kcal),
        item_count: row.item_count,
        daily_cap_mg: DAILY_SODIUM_CAP_MG,
        progress_fraction: parseFloat(progress.toFixed(4)),
        is_over_limit: isOverLimit,
        remaining_mg: Math.max(0, DAILY_SODIUM_CAP_MG - totalSodium),
      });
    } catch (err) {
      logger.error('getDailySodiumSummary error', { error: err.message });
      res.status(500).json({ error: 'Failed to compute sodium summary.' });
    }
  },

  // ── Remove a food log entry ──────────────────────────────────
  async deleteFoodEntry(req, res) {
    try {
      const result = await query(
        `DELETE FROM daily_food_logs WHERE id = $1 AND user_id = $2`,
        [req.params.id, req.userId],
      );
      if (!result.rowCount) return res.status(404).json({ error: 'Entry not found.' });
      res.json({ message: 'Entry deleted.' });
    } catch (err) {
      logger.error('deleteFoodEntry error', { error: err.message });
      res.status(500).json({ error: 'Failed to delete entry.' });
    }
  },
};

module.exports = DietController;
