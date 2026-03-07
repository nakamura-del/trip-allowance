-- v1 → v2 マイグレーション
-- 既存データがある場合に Supabase SQL Editor で実行

-- 1. 従業員テーブル作成
CREATE TABLE IF NOT EXISTS employees (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  position TEXT NOT NULL DEFAULT '一般',
  login_id TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  is_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. trip_records に新カラム追加
ALTER TABLE trip_records ADD COLUMN IF NOT EXISTS employee_id INTEGER;
ALTER TABLE trip_records ADD COLUMN IF NOT EXISTS employee_name TEXT;
ALTER TABLE trip_records ADD COLUMN IF NOT EXISTS employee_position TEXT;
ALTER TABLE trip_records ADD COLUMN IF NOT EXISTS record_type TEXT DEFAULT 'travel';
ALTER TABLE trip_records ADD COLUMN IF NOT EXISTS hotel_name TEXT;

-- 既存レコードのrecord_typeをセット
UPDATE trip_records SET record_type = 'travel' WHERE record_type IS NULL;

-- 3. app_config に positions カラム追加
ALTER TABLE app_config ADD COLUMN IF NOT EXISTS positions JSONB;

-- 既存の tiers データを positions 形式に変換
UPDATE app_config SET positions = jsonb_build_array(
  jsonb_build_object(
    'name', '一般',
    'travel_tiers', COALESCE(tiers, '[{"min":0,"max":50,"label":"50km未満","allowance":0},{"min":50,"max":100,"label":"50km以上100km未満","allowance":5000},{"min":100,"max":200,"label":"100km以上200km未満","allowance":10000},{"min":200,"max":9999,"label":"200km以上","allowance":20000}]'::jsonb),
    'accommodation_allowance', 8700
  )
) WHERE id = 1 AND positions IS NULL;

-- 4. デフォルト管理者ユーザー作成（既存のモバイルパスワードを使用）
INSERT INTO employees (name, position, login_id, password, is_admin)
SELECT '管理者', '一般', 'admin', COALESCE(mobile_password, 'admin1234'), true
FROM app_config WHERE id = 1
ON CONFLICT (login_id) DO NOTHING;

-- 5. 既存レコードを管理者ユーザーに紐付け
UPDATE trip_records
SET employee_id = (SELECT id FROM employees WHERE login_id = 'admin' LIMIT 1),
    employee_name = '管理者',
    employee_position = '一般'
WHERE employee_id IS NULL;

-- 6. RLS設定
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'employees' AND policyname = 'Allow all on employees') THEN
    CREATE POLICY "Allow all on employees" ON employees FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
