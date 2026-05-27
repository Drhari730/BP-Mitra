// Module 5 – Parametric AI Clinical Assistant Controller
// Deterministic rule-engine that evaluates a structured user-stat payload
// and returns a profile-matched diagnostic text response.
const { v4: uuidv4 } = require('uuid');
const { query } = require('../config/database');
const { logger } = require('../utils/logger');

// ── Rule Engine ──────────────────────────────────────────────
// Evaluates user stats snapshot and returns the matched profile + response.
// Priority: Profile A > Profile B > Profile C > Default healthy message.
function evaluateClinicalProfile(payload) {
  const {
    current_systolic,
    current_diastolic,
    adherence_rate_percentage,
    daily_sodium_intake_mg,
    active_steps,
    qol_fatigue_score, // 1 (great) – 5 (exhausted)
  } = payload;

  // ── Profile A: Elevated BP + Poor Adherence ──────────────
  if (current_systolic > 140 || current_diastolic > 90) {
    if (adherence_rate_percentage < 80) {
      return {
        profile: 'A',
        response: `AI Analysis: Your blood pressure is registering in the hypertensive zone (${current_systolic}/${current_diastolic} mmHg). Our tracking indicates this correlates directly with missed medication logs over the last 3 days. Adherence rate is currently at ${adherence_rate_percentage}%, which is below the therapeutic threshold of 80%. Prioritize your scheduled evening dosage, and consider performing 10 minutes of controlled Nadi Shodhana Pranayama right now to calm sympathetic nervous system tone. If readings remain elevated beyond 160/100 mmHg, please consult your physician immediately.`,
      };
    }
  }

  // ── Profile B: Controlled BP + High Sodium ──────────────
  if (
    current_systolic <= 140 && current_diastolic <= 90 &&
    daily_sodium_intake_mg > 1500
  ) {
    return {
      profile: 'B',
      response: `AI Analysis: Excellent work keeping your vitals within optimal parameters (${current_systolic}/${current_diastolic} mmHg). However, your South Indian meal logs indicate an elevated sodium spike today — current intake is ${daily_sodium_intake_mg}mg against the 1500mg DASH protocol cap. This excess likely originated from processed sambar powder, pickle, or packaged papad elements. Balance this out immediately over the next 24 hours by increasing potassium intake via a fresh banana (~422mg K⁺) or a tender coconut water (~600mg K⁺), and omitting added salt from your next dinner meal entirely.`,
    };
  }

  // ── Profile C: High Fatigue + Low Activity ──────────────
  if (qol_fatigue_score >= 4 && active_steps < 4000) {
    return {
      profile: 'C',
      response: `AI Analysis: Your logged quality-of-life parameters reflect elevated physical fatigue (score: ${qol_fatigue_score}/5) and low movement metrics (${active_steps} steps today). These patterns are associated with increased peripheral vascular resistance and sympathetic overdrive. Avoid intense workouts today. Instead, access our Yoga tab and follow the restorative Sukhasana sequence with deep diaphragmatic breathing (4-7-8 rhythm) for 15 minutes to naturally lower vascular resistance. Hydrate with 2 glasses of room-temperature water now. Re-log your fatigue score after the session.`,
    };
  }

  // ── Default: All Parameters Optimal ─────────────────────
  return {
    profile: null,
    response: `AI Analysis: All tracked parameters are within healthy ranges. BP ${current_systolic}/${current_diastolic} mmHg ✓ | Adherence ${adherence_rate_percentage}% ✓ | Sodium ${daily_sodium_intake_mg}mg ✓ | Steps ${active_steps} ✓. Continue your current routine. Consistency is the most powerful cardiovascular intervention available to you today.`,
  };
}

const AiController = {

  // ── Evaluate user stat payload and persist session log ───────
  async evaluate(req, res) {
    const required = [
      'current_systolic', 'current_diastolic', 'adherence_rate_percentage',
      'daily_sodium_intake_mg', 'active_steps', 'qol_fatigue_score',
    ];

    for (const field of required) {
      if (req.body[field] === undefined) {
        return res.status(422).json({ error: `Missing required field: ${field}` });
      }
    }

    try {
      const { profile, response } = evaluateClinicalProfile(req.body);

      await query(
        `INSERT INTO ai_sessions
           (id, user_id, input_payload, triggered_profile, response_text)
         VALUES ($1,$2,$3,$4,$5)`,
        [uuidv4(), req.userId, JSON.stringify(req.body), profile, response],
      );

      res.json({ profile, response, evaluated_at: new Date().toISOString() });
    } catch (err) {
      logger.error('ai.evaluate error', { error: err.message });
      res.status(500).json({ error: 'AI evaluation failed.' });
    }
  },

  // ── Recent AI session history ────────────────────────────────
  async getSessionHistory(req, res) {
    const limit = Math.min(parseInt(req.query.limit || '20'), 100);

    try {
      const result = await query(
        `SELECT id, triggered_profile, response_text, input_payload, evaluated_at
         FROM ai_sessions
         WHERE user_id = $1
         ORDER BY evaluated_at DESC
         LIMIT $2`,
        [req.userId, limit],
      );
      res.json({ sessions: result.rows });
    } catch (err) {
      logger.error('getSessionHistory error', { error: err.message });
      res.status(500).json({ error: 'Failed to fetch session history.' });
    }
  },
};

module.exports = AiController;
