-- Supabase setup SQL
-- Run this in Supabase SQL Editor

-- Records table
CREATE TABLE trip_records (
  id BIGINT PRIMARY KEY,
  date TEXT NOT NULL,
  depart_time TEXT,
  arrive_time TEXT,
  depart_gps JSONB,
  arrive_gps JSONB,
  distance REAL NOT NULL DEFAULT 0,
  tier TEXT,
  allowance INTEGER NOT NULL DEFAULT 0,
  purpose TEXT DEFAULT '',
  person TEXT DEFAULT '',
  edit_history JSONB DEFAULT '[]'::jsonb,
  submitted_at TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Config table
CREATE TABLE app_config (
  id INTEGER PRIMARY KEY DEFAULT 1,
  admin_password TEXT DEFAULT 'admin5678',
  mobile_password TEXT DEFAULT 'admin1234',
  tiers JSONB DEFAULT '[
    {"min":0,"max":50,"label":"50km未満","allowance":0},
    {"min":50,"max":100,"label":"50km以上100km未満","allowance":5000},
    {"min":100,"max":200,"label":"100km以上200km未満","allowance":10000},
    {"min":200,"max":9999,"label":"200km以上","allowance":20000}
  ]'::jsonb
);

-- Insert default config
INSERT INTO app_config (id) VALUES (1);

-- Enable RLS
ALTER TABLE trip_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;

-- Allow anonymous access (app handles auth with simple passwords)
CREATE POLICY "Allow all on trip_records" ON trip_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on app_config" ON app_config FOR ALL USING (true) WITH CHECK (true);
