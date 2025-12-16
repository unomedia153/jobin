-- JobIn (인력사무소 중개 플랫폼) Supabase Database Schema
-- 모든 테이블은 created_at, updated_at, deleted_at 컬럼을 포함합니다.

-- ============================================
-- 1. Profiles (사용자 프로필)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL CHECK (role IN ('manager', 'client', 'worker')),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 2. Agencies (송출회사)
-- ============================================
CREATE TABLE IF NOT EXISTS agencies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 3. Sites (현장)
-- ============================================
CREATE TABLE IF NOT EXISTS sites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  radius INTEGER NOT NULL DEFAULT 30,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 4. Job Orders (작업 주문)
-- ============================================
CREATE TABLE IF NOT EXISTS job_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  site_id UUID NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
  work_date DATE NOT NULL,
  work_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 5. Placements (배치)
-- ============================================
CREATE TABLE IF NOT EXISTS placements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_order_id UUID NOT NULL REFERENCES job_orders(id) ON DELETE CASCADE,
  worker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('offered', 'accepted', 'rejected')),
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- 6. Ledgers (장부)
-- ============================================
CREATE TABLE IF NOT EXISTS ledgers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agency_id UUID NOT NULL REFERENCES agencies(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ============================================
-- Indexes (성능 최적화)
-- ============================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_phone ON profiles(phone) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_agencies_owner_id ON agencies(owner_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_sites_agency_id ON sites(agency_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_job_orders_site_id ON job_orders(site_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_job_orders_work_date ON job_orders(work_date) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_placements_worker_id ON placements(worker_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_placements_job_order_id ON placements(job_order_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_placements_status ON placements(status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_ledgers_agency_id ON ledgers(agency_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_ledgers_type ON ledgers(type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_ledgers_created_at ON ledgers(created_at) WHERE deleted_at IS NULL;

-- ============================================
-- Triggers (updated_at 자동 업데이트)
-- ============================================
-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 updated_at 트리거 적용
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_agencies_updated_at
  BEFORE UPDATE ON agencies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sites_updated_at
  BEFORE UPDATE ON sites
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_job_orders_updated_at
  BEFORE UPDATE ON job_orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_placements_updated_at
  BEFORE UPDATE ON placements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ledgers_updated_at
  BEFORE UPDATE ON ledgers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS) 정책
-- ============================================
-- RLS 활성화
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE placements ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledgers ENABLE ROW LEVEL SECURITY;

-- 기본 정책: 자신의 프로필은 조회/수정 가능
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- 소장은 자신의 회사 정보 조회 가능
CREATE POLICY "Managers can view own agency"
  ON agencies FOR SELECT
  USING (
    owner_id IN (
      SELECT id FROM profiles WHERE id = auth.uid()
    )
  );

-- 소장은 자신의 회사 현장 조회 가능
CREATE POLICY "Managers can view own agency sites"
  ON sites FOR SELECT
  USING (
    agency_id IN (
      SELECT id FROM agencies WHERE owner_id = auth.uid()
    )
  );

-- 작업자는 자신에게 온 배치의향서 조회 가능
CREATE POLICY "Workers can view own placements"
  ON placements FOR SELECT
  USING (
    worker_id = auth.uid() OR
    job_order_id IN (
      SELECT jo.id FROM job_orders jo
      JOIN sites s ON jo.site_id = s.id
      JOIN agencies a ON s.agency_id = a.id
      WHERE a.owner_id = auth.uid()
    )
  );

-- 작업자는 자신의 배치 수락/거절 가능
CREATE POLICY "Workers can update own placements"
  ON placements FOR UPDATE
  USING (worker_id = auth.uid());

-- 소장은 자신의 회사 장부 조회 가능
CREATE POLICY "Managers can view own agency ledgers"
  ON ledgers FOR SELECT
  USING (
    agency_id IN (
      SELECT id FROM agencies WHERE owner_id = auth.uid()
    )
  );

-- 소장은 자신의 회사 장부 생성 가능
CREATE POLICY "Managers can create own agency ledgers"
  ON ledgers FOR INSERT
  WITH CHECK (
    agency_id IN (
      SELECT id FROM agencies WHERE owner_id = auth.uid()
    )
  );

-- ============================================
-- Comments (테이블 설명)
-- ============================================
COMMENT ON TABLE profiles IS '사용자 프로필 (소장, 고객사 관리자, 작업자)';
COMMENT ON TABLE agencies IS '송출회사 정보';
COMMENT ON TABLE sites IS '현장 정보 (GPS 좌표 포함)';
COMMENT ON TABLE job_orders IS '작업 주문 (일감)';
COMMENT ON TABLE placements IS '배치 정보 (배치의향서, 수락, 거절 상태)';
COMMENT ON TABLE ledgers IS '장부 (수입/지출 기록)';

