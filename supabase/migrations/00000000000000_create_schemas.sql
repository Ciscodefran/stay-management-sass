-- =====================================
-- 스키마 생성
-- =====================================
--
-- 이 마이그레이션은 PostgreSQL 스키마들만 생성합니다.
-- 테이블은 Drizzle이 생성합니다 (0000_*.sql).
--
-- 스키마 목적:
--   iam: Identity & Access Management (사용자, 인증, 권한)
--   org: Organization (테넌트, 조직)
--   biz: Business (비즈니스 도메인 - 예약, 결제 등)
--   ref: Reference (참조 데이터, 조회 테이블)
--   pub: Public (공개 뷰, 집계 데이터)
--

CREATE SCHEMA IF NOT EXISTS iam;
CREATE SCHEMA IF NOT EXISTS org;
CREATE SCHEMA IF NOT EXISTS biz;
CREATE SCHEMA IF NOT EXISTS ref;
CREATE SCHEMA IF NOT EXISTS pub;
