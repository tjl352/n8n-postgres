-- Schema for the "My workflow" job-lead pipeline (Gmail Trigger -> AI Agent -> Postgres).
-- Kept in its own schema so it stays separate from n8n's internal tables in `public`.
-- Apply with: docker exec -i n8n_postgres psql -U n8n_user -d n8n_database < sql/schema.sql

CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE IF NOT EXISTS app.job_leads (
  id SERIAL PRIMARY KEY,
  recruiter_name TEXT,
  recruiter_phone TEXT,
  recruiter_email TEXT,
  recruiter_linkedin TEXT,
  job_title TEXT,
  job_skills TEXT,
  job_description TEXT,
  job_duties TEXT,
  job_technologies TEXT,
  job_tools TEXT,
  job_location TEXT,
  job_client TEXT,
  job_pay TEXT,
  job_type TEXT,
  email_sent_date TEXT,
  received_at TIMESTAMPTZ DEFAULT now()
);
