-- v2 → v3 マルチテナント マイグレーション
-- 既存データがある場合に Supabase SQL Editor で実行

-- 1. 会社テーブル作成
CREATE TABLE IF NOT EXISTS companies (
  company_code TEXT PRIMARY KEY,
  company_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. デフォルト会社を作成（既存データ用）
INSERT INTO companies (company_code, company_name)
VALUES ('default', 'デフォルト会社')
ON CONFLICT (company_code) DO NOTHING;

-- 3. employees に company_code 追加
ALTER TABLE employees ADD COLUMN IF NOT EXISTS company_code TEXT;
UPDATE employees SET company_code = 'default' WHERE company_code IS NULL;
ALTER TABLE employees ALTER COLUMN company_code SET NOT NULL;

-- login_id のユニーク制約を (company_code, login_id) に変更
ALTER TABLE employees DROP CONSTRAINT IF EXISTS employees_login_id_key;
CREATE UNIQUE INDEX IF NOT EXISTS employees_company_login_id_key ON employees(company_code, login_id);

-- 外部キー追加
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'employees_company_code_fkey') THEN
    ALTER TABLE employees ADD CONSTRAINT employees_company_code_fkey FOREIGN KEY (company_code) REFERENCES companies(company_code);
  END IF;
END $$;

-- 4. trip_records に company_code 追加
ALTER TABLE trip_records ADD COLUMN IF NOT EXISTS company_code TEXT;
UPDATE trip_records SET company_code = 'default' WHERE company_code IS NULL;
ALTER TABLE trip_records ALTER COLUMN company_code SET NOT NULL;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'trip_records_company_code_fkey') THEN
    ALTER TABLE trip_records ADD CONSTRAINT trip_records_company_code_fkey FOREIGN KEY (company_code) REFERENCES companies(company_code);
  END IF;
END $$;

-- 5. app_config に company_code 追加
ALTER TABLE app_config ADD COLUMN IF NOT EXISTS company_code TEXT;
UPDATE app_config SET company_code = 'default' WHERE company_code IS NULL;
ALTER TABLE app_config ALTER COLUMN company_code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS app_config_company_code_key ON app_config(company_code);

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'app_config_company_code_fkey') THEN
    ALTER TABLE app_config ADD CONSTRAINT app_config_company_code_fkey FOREIGN KEY (company_code) REFERENCES companies(company_code);
  END IF;
END $$;

-- 6. インデックス追加
CREATE INDEX IF NOT EXISTS idx_employees_company ON employees(company_code);
CREATE INDEX IF NOT EXISTS idx_trip_records_company ON trip_records(company_code);
CREATE INDEX IF NOT EXISTS idx_trip_records_date ON trip_records(company_code, date);

-- 7. companies テーブルの RLS
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'companies' AND policyname = 'Allow all on companies') THEN
    CREATE POLICY "Allow all on companies" ON companies FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
