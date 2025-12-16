-- Job Orders 테이블에 필요한 필드 추가
-- 필요 인원, 단가, 메모 필드를 추가합니다.

ALTER TABLE job_orders
ADD COLUMN IF NOT EXISTS required_workers INTEGER NOT NULL DEFAULT 1;

ALTER TABLE job_orders
ADD COLUMN IF NOT EXISTS unit_price INTEGER;

ALTER TABLE job_orders
ADD COLUMN IF NOT EXISTS memo TEXT;

-- 주석 추가
COMMENT ON COLUMN job_orders.required_workers IS '필요 인원 수';
COMMENT ON COLUMN job_orders.unit_price IS '단가 (노임)';
COMMENT ON COLUMN job_orders.memo IS '메모 (특이사항)';

-- Sites 테이블에 필요한 필드 추가
-- 담당자, 전화번호, 주소 필드를 추가합니다.

ALTER TABLE sites
ADD COLUMN IF NOT EXISTS contact_name TEXT;

ALTER TABLE sites
ADD COLUMN IF NOT EXISTS contact_phone TEXT;

ALTER TABLE sites
ADD COLUMN IF NOT EXISTS address TEXT;

-- 주석 추가
COMMENT ON COLUMN sites.contact_name IS '담당자명';
COMMENT ON COLUMN sites.contact_phone IS '전화번호';
COMMENT ON COLUMN sites.address IS '주소';

