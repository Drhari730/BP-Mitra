-- Demo seed: inserts a sample user and medication schedule for development.
-- Run ONLY in development environment; never in production.

-- Demo user (password: DemoPass123!)
INSERT INTO users (id, full_name, email, password_hash, hypertension_stage)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Rajan Krishnamurthy',
  'rajan@bpmitra.dev',
  '$2b$12$XHKbVqzKjR9IpvvHYr0sxuvKVxKnH8yHMXTg2uHvRj2PFGa0cKAaO', -- DemoPass123!
  'stage1'
) ON CONFLICT (email) DO NOTHING;

-- Medication schedule: Telmisartan 40mg daily at 8:00 AM
INSERT INTO medication_schedules
  (id, user_id, med_name, dosage_mg, frequency_hours, scheduled_time, drug_class, is_critical)
VALUES (
  '00000000-0000-0000-0001-000000000001',
  '00000000-0000-0000-0000-000000000001',
  'Telmisartan',
  40,
  24,
  '08:00',
  'ARB antihypertensive',
  TRUE
) ON CONFLICT DO NOTHING;

-- Medication schedule: Amlodipine 5mg daily at 8:00 PM
INSERT INTO medication_schedules
  (id, user_id, med_name, dosage_mg, frequency_hours, scheduled_time, drug_class, is_critical)
VALUES (
  '00000000-0000-0000-0001-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'Amlodipine',
  5,
  24,
  '20:00',
  'CCB antihypertensive',
  TRUE
) ON CONFLICT DO NOTHING;
