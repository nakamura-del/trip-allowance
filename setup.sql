-- Supabase setup SQL (v2 - マルチユーザー・宿泊日当対応)
-- 新規セットアップ時に Supabase SQL Editor で実行

-- 従業員テーブル
CREATE TABLE employees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  position TEXT NOT NULL DEFAULT '一般',
  login_id TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 移動・宿泊記録テーブル
CREATE TABLE trip_records (
  id BIGINT PRIMARY KEY,
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

-- 設定テーブル
CREATE TABLE app_config (
  id INTEGER PRIMARY KEY DEFAULT 1,
  admin_password TEXT DEFAULT 'admin5678',
  positions JSONB DEFAULT '[{"name":"一般","travel_tiers":[{"min":0,"max":50,"label":"50km未満","allowance":0},{"min":50,"max":100,"label":"50km以上100km未満","allowance":5000},{"min":100,"max":200,"label":"100km以上200km未満","allowance":10000},{"min":200,"max":9999,"label":"200km以上","allowance":20000}],"accommodation_allowance":8700}]'::jsonb
);

-- デフォルト設定を挿入
INSERT INTO app_config (id) VALUES (1);

-- デフォルト管理者を作成
INSERT INTO employees (name, position, login_id, password, is_admin)
VALUES ('管理者', '一般', 'admin', 'admin1234', true);

-- RLS有効化
ALTER TABLE trip_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- 匿名アクセス許可（アプリ側でパスワード認証）
CREATE POLICY "Allow all on trip_records" ON trip_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on app_config" ON app_config FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all on employees" ON employees FOR ALL USING (true) WITH CHECK (true);
