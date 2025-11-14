# @stay/db

Stay Management SaaS 프로젝트의 데이터베이스 패키지입니다. Drizzle ORM을 사용하여 타입 안전한 데이터베이스 접근을 제공합니다.

## 📦 설치

이 패키지는 모노레포 내부에서 사용됩니다:

```json
{
  "dependencies": {
    "@stay/db": "workspace:*"
  }
}
```

## 🏗️ 아키텍처

### 스키마 구성

- **iam** (Identity & Access Management): 사용자, 인증, 권한
- **org** (Organization): 테넌트, 조직
- **biz** (Business): 비즈니스 도메인 (예약 등)
- **ref** (Reference): 참조 데이터
- **pub** (Public): 공개 뷰

### 디렉토리 구조

```
packages/db/
├── src/
│   ├── schema/          # Drizzle 스키마 정의
│   │   ├── iam/        # IAM 테이블
│   │   ├── org/        # ORG 테이블
│   │   ├── biz/        # BIZ 테이블
│   │   ├── ref/        # REF 테이블
│   │   └── pub/        # PUB 뷰
│   ├── utils/          # 유틸리티 (스키마 헬퍼 등)
│   ├── index.ts        # 스키마만 export (React Native 호환)
│   └── client.ts       # DB 클라이언트 (서버 사이드 전용)
├── drizzle.config.ts   # Drizzle 설정
└── README.md
```

## 📝 사용법

### 스키마만 import (모든 환경)

```typescript
import { users, tenants, bookings } from '@stay/db';

// TypeScript 타입
import type { User, Tenant, Booking } from '@stay/db';
```

### DB 클라이언트 import (서버 사이드만)

```typescript
import { db } from '@stay/db/client';

// 쿼리 실행
const allUsers = await db.select().from(users);
```

**⚠️ 주의**: React Native 앱에서는 `@stay/db/client`를 import하지 마세요. 스키마만 사용하세요.

## 🔧 개발 가이드

### 스키마 수정 워크플로우

1. **TypeScript 스키마 수정**
```typescript
// packages/db/src/schema/biz/properties.ts
export const properties = bizSchema.table('properties', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  tenantId: uuid('tenant_id').notNull(),
  name: text('name').notNull(),
  // ...
});
```

2. **마이그레이션 생성**
```bash
cd packages/db
pnpm db:generate
```

3. **마이그레이션 확인**
```bash
# supabase/migrations/ 에 새 파일 생성됨
ls -la ../../supabase/migrations/
```

4. **적용 및 테스트**
```bash
cd ../..
supabase db reset
```

### 사용 가능한 스크립트

```bash
# 마이그레이션 생성
pnpm db:generate

# 마이그레이션 적용
pnpm db:migrate

# 데이터베이스에 직접 push (개발용)
pnpm db:push

# Drizzle Studio 실행 (GUI)
pnpm db:studio

# 타입 체크
pnpm check-types
```

## 🔐 보안 고려사항

### Row Level Security (RLS)

모든 테이블은 RLS로 보호됩니다. Drizzle 쿼리는 자동으로 RLS 정책을 따릅니다:

```typescript
// JWT 클레임의 active_tenant_id로 자동 필터링됨
const bookings = await db
  .select()
  .from(bookingsTable)
  .where(eq(bookingsTable.tenantId, tenantId));
```

### 환경 변수

`.env` 파일에 다음 변수를 설정하세요:

```bash
DATABASE_URL=postgresql://postgres:postgres@localhost:54322/postgres
```

## 📚 주요 테이블

### IAM Schema

| 테이블 | 설명 |
|--------|------|
| users | 사용자 계정 |
| user_identities | 외부 인증 (Supabase Auth) |
| role_types | 역할 타입 (owner, admin, member, viewer) |
| user_tenants | 사용자-테넌트 관계 |
| session_contexts | 세션 컨텍스트 |

### ORG Schema

| 테이블 | 설명 |
|--------|------|
| tenants | 멀티테넌트 조직 |

### BIZ Schema

| 테이블 | 설명 |
|--------|------|
| bookings | 예약 정보 |

### REF Schema

| 테이블 | 설명 |
|--------|------|
| tenant_status_types | 테넌트 상태 (active, suspended, archived) |

## 🎯 타입 안전성

Drizzle은 완전한 타입 안전성을 제공합니다:

```typescript
import { users } from '@stay/db';
import type { User, NewUser } from '@stay/db';

// SELECT - 타입 추론됨
const user: User = await db
  .select()
  .from(users)
  .where(eq(users.id, userId))
  .limit(1);

// INSERT - 타입 체크됨
const newUser: NewUser = {
  status: 'active', // ✅ 타입 안전
  // status: 'invalid', // ❌ 타입 에러
};
await db.insert(users).values(newUser);
```

## 🔗 관련 문서

- [Drizzle ORM 공식 문서](https://orm.drizzle.team/)
- [마이그레이션 가이드](../../supabase/migrations/README.md)
- [Supabase 로컬 개발](https://supabase.com/docs/guides/cli)

## 🤝 기여 가이드

### 새 테이블 추가

1. 적절한 스키마 폴더에 파일 생성 (`src/schema/*/`)
2. Drizzle 테이블 정의 작성
3. 인덱스 폴더 (`index.ts`)에 export 추가
4. `pnpm db:generate`로 마이그레이션 생성
5. 필요시 RLS 정책 추가 (수동 SQL)

### 컬럼 수정

1. TypeScript 스키마 파일 수정
2. `pnpm db:generate`로 마이그레이션 생성
3. 생성된 마이그레이션 확인
4. `supabase db reset`으로 테스트

## ⚠️ 주의사항

### Drizzle vs 수동 SQL

- **Drizzle로 관리**: 테이블, 컬럼, FK, 기본 인덱스
- **수동 SQL로 관리**: RLS 정책, 복잡한 함수, 트리거

Drizzle로 생성된 마이그레이션 후에 수동 SQL 마이그레이션을 추가하세요.

### React Native 호환성

- ✅ `import { users } from '@stay/db'` - 스키마만 (OK)
- ❌ `import { db } from '@stay/db/client'` - DB 연결 (서버만)

### 마이그레이션 순서

파일명으로 자동 정렬되므로 순서가 중요합니다:
1. `00000000000000_*`: 스키마 생성
2. `0000_*`: Drizzle 테이블
3. `0001_*`, `0002_*`: 수동 SQL
