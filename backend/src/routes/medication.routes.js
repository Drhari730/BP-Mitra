// Medication Tracker – Express router wiring Module 1 endpoints.
const { Router } = require('express');
const { authenticate } = require('../middleware/auth.middleware');
const MedicationController = require('../controllers/medication.controller');

const router = Router();

// All endpoints require authenticated user context.
router.use(authenticate);

// Medication Schedules CRUD
router.get('/schedules', MedicationController.listSchedules);
router.post('/schedules', MedicationController.createSchedule);
router.patch('/schedules/:id', MedicationController.updateSchedule);
router.delete('/schedules/:id', MedicationController.deleteSchedule);

// Adherence Logging
router.post('/log', MedicationController.logAdherence);
router.get('/logs', MedicationController.getAdherenceLogs);
router.get('/streak', MedicationController.getAdherenceStreak);
router.get('/summary', MedicationController.getAdherenceSummary);

module.exports = router;
