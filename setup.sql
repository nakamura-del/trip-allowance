-- Supabase setup SQL (v3 - マルチテナント対応)
-- 新規セットアップ時に Supabase SQL Editor で実行

-- 会社テーブル
CREATE TABLE companies (
  company_code TEXT PRIMARY KEY,
  company_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 従業員テーブル
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  company_code TEXT NOT NULL REFERENCES companies(company_code),
  name TEXT NOT NULL,
  position TEXT NOT NULL DEFAULT '一般',
  login_id TEXT NOT NULL,
  password TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company_code, login_id)
);

-- 移動・宿泊記録テーブル
CREATE TABLE trip_records (
  id BIGINT PRIMARY KEY,
  company_code TEXT NOT NULL REFERENCES companies(company_code),
  employee_id INTEGER,
  employee_name TEXT,
  employee_position TEXT,
  record_type TEXT NOT NULL DEFAULT 'travel',
  date TEXT NOT NULL,
  depart_time TEXT,
  arrive_time TEXT,
  depart_gps JSONB,
  arrive_gps JSONB,
  distance REAL NOT NULL DEFAULT 0,
  tier TEXT,
  allowance INTEGER NOT NULL DEFAULT 0,
  hotel_name TEXT,
  purpose TEXT DEFAULT '',
  person TEXT DEFAULT '',
  edit_history JSONB DEFAULT '[]'::jsonb,
  submitted_at TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 設定テーブル（会社ごとに1行）
CREATE TABLE app_config (
  id SERIAL PRIMARY KEY,
  company_code TEXT NOT NULL UNIQUE REFERENCES companies(company_code),
  admin_password TEXT DEFAULT 'admin5678',
  positions JSONB DEFAULT '[{"name":"一般","travel_tiers":[{"min":0,"max":50,"label":"50km未満","allowance":0},{"min":50,"max":100,"label":"50km以上100km未満","allowance":5000},{"min":100,"max":200,"label":"100km以上200km未満","allowance":10000},{"min":200,"max":9999,"label":"200km以上","allowance":20000}],"accommodation_allowance":8700}]'::jsonb,
  pdf_filename TEXT,
  pdf_uploaded_at TIMESTAMPTZ
);

-- インデックス
CREATE INDEX idx_employees_company ON employees(company_code);
CREATE INDEX idx_trip_records_company ON trip_records(company_code);
CREATE INDEX idx_trip_records_date ON trip_records(company_code, date);

-- RLS有効化
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- 匿名アクセス許可（アプリ側でパスワード認証）
CREATE POLICY "Allow all on companies" ON companies FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on trip_records" ON trip_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on app_config" ON app_config FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on employees" ON employees FOR ALL USING (true) WITH CHECK (true);
