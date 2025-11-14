# Stay Management SaaS

Turborepo 기반 모노레포 프로젝트

## 🚀 배포된 애플리케이션

- **ERP 앱**: [https://stay-management-sass-erp.vercel.app/](https://stay-management-sass-erp.vercel.app/)
- **Console 앱**: [https://stay-management-sass-console.vercel.app/](https://stay-management-sass-console.vercel.app/)

## 프로젝트 구조

```
stay-management-sass/
├── apps/
│   ├── erp/                    # ERP 애플리케이션
│   │                           # 🌐 https://stay-management-sass-erp.vercel.app/
│   │                           # 🏠 http://localhost:3000
│   └── console/                # Console 애플리케이션
│                               # 🌐 https://stay-management-sass-console.vercel.app/
│                               # 🏠 http://localhost:3001
├── packages/
│   ├── eslint-config/          # ESLint 공유 설정 (포매팅 포함)
│   ├── typescript-config/      # TypeScript 공유 설정
│   └── ui/                     # Radix UI 기반 공유 컴포넌트
├── turbo.json                  # Turborepo 설정
├── pnpm-workspace.yaml         # PNPM 워크스페이스
└── package.json                # 루트 package.json
```

## 기술 스택

- **빌드 시스템**: Turborepo
- **패키지 관리자**: PNPM (v9.15.0+)
- **프레임워크**: Next.js 15
- **언어**: TypeScript 5.7
- **스타일링**: Tailwind CSS
- **UI 컴포넌트**: Radix UI
- **린팅**: ESLint (포매팅 포함)

## 시작하기

### 필수 요구사항

- Node.js >= 20.0.0
- PNPM >= 9.0.0

### 설치

```bash
# PNPM 설치 (없는 경우)
npm install -g pnpm

# 의존성 설치
pnpm install
```

### 개발 서버 실행

```bash
# 모든 앱 동시 실행
pnpm dev

# 특정 앱만 실행
pnpm --filter erp dev      # ERP 앱 (http://localhost:3000)
pnpm --filter console dev  # Console 앱 (http://localhost:3001)
```

### 빌드

```bash
# 모든 앱 빌드
pnpm build

# 특정 앱만 빌드
pnpm --filter erp build
pnpm --filter console build
```

### 린팅 및 포매팅

```bash
# 모든 패키지 린팅
pnpm lint

# 자동 수정 (포매팅 포함)
pnpm lint:fix

# 특정 앱만 린팅
pnpm --filter erp lint:fix
```

### 타입 체크

```bash
# 모든 패키지 타입 체크
pnpm type-check

# 특정 앱만 타입 체크
pnpm --filter console type-check
```

### 클린업

```bash
# 모든 빌드 결과 및 node_modules 삭제
pnpm clean
```

## 패키지 설명

### Apps

#### ERP (`apps/erp`)
- **배포 URL**: [https://stay-management-sass-erp.vercel.app/](https://stay-management-sass-erp.vercel.app/)
- **로컬 포트**: 3000
- **테마**: 커스텀 브랜드 테마 (블루 계열)
- **스타일**: Radix UI + 커스텀 디자인
- **설명**: Stay Management ERP 애플리케이션

#### Console (`apps/console`)
- **배포 URL**: [https://stay-management-sass-console.vercel.app/](https://stay-management-sass-console.vercel.app/)
- **로컬 포트**: 3001
- **테마**: shadcn 기본 테마
- **스타일**: Radix UI + shadcn 스타일
- **설명**: Stay Management Console 애플리케이션

### Packages

#### @repo/eslint-config
ESLint 공유 설정 패키지 (포매팅 포함)
- `base.js`: 기본 ESLint 규칙 + 포매팅 규칙
- `next.js`: Next.js 전용 규칙
- `library.js`: 라이브러리/패키지 전용 규칙

**주요 특징**:
- Prettier 대신 ESLint로 포매팅 처리
- 일관된 코드 스타일 강제
- Import 자동 정렬

#### @repo/typescript-config
TypeScript 공유 설정 패키지
- `base.json`: 기본 TypeScript 설정
- `nextjs.json`: Next.js 전용 설정
- `library.json`: 라이브러리 전용 설정

#### @repo/ui
Radix UI 기반 공유 UI 컴포넌트 라이브러리

**특징**:
- Radix UI 기반으로 접근성 우수
- shadcn 스타일 호환
- 각 앱에서 독립적인 테마 커스터마이징 가능
- Tailwind CSS preset 제공

**사용 방법**:
```tsx
import { cn } from '@repo/ui';

// 유틸리티 함수 사용
const className = cn('text-primary', 'font-bold');
```

자세한 내용은 [packages/ui/README.md](packages/ui/README.md)를 참고하세요.

## 개발 가이드

### 새 컴포넌트 추가

1. `packages/ui/src/components/ui/`에 컴포넌트 파일 생성
2. 필요한 Radix UI 패키지 설치
3. `packages/ui/src/index.ts`에 export 추가
4. 앱에서 import하여 사용

자세한 가이드는 [packages/ui/README.md](packages/ui/README.md)를 참고하세요.

### 새 앱 추가

```bash
# apps 디렉토리에 새 Next.js 앱 생성
cd apps
pnpx create-next-app@latest new-app --typescript --tailwind --app

# 공유 패키지 추가
cd new-app
pnpm add @repo/ui@workspace:* -D @repo/eslint-config@workspace:* \
  @repo/typescript-config@workspace:*

# tsconfig.json, .eslintrc.js, tailwind.config.ts 설정
# (기존 앱 참고)
```

### 의존성 추가

```bash
# 특정 앱에 의존성 추가
pnpm --filter erp add <package-name>

# 워크스페이스 루트에 의존성 추가
pnpm add -w <package-name>

# 개발 의존성 추가
pnpm --filter console add -D <package-name>
```

## 린팅 규칙

이 프로젝트는 Prettier 대신 ESLint로 포매팅을 처리합니다.

### 주요 포매팅 규칙

- **들여쓰기**: 2칸 스페이스
- **따옴표**: 작은따옴표 (')
- **세미콜론**: 필수
- **최대 줄 길이**: 100자
- **후행 쉼표**: 여러 줄에서 필수

### 자동 포매팅

```bash
# ESLint로 자동 포매팅
pnpm lint:fix
```

## 문제 해결

### pnpm install 실패

```bash
# node_modules 및 lock 파일 삭제 후 재설치
rm -rf node_modules apps/*/node_modules packages/*/node_modules
rm pnpm-lock.yaml
pnpm install
```

### 타입 에러

```bash
# 타입 체크 실행
pnpm type-check

# Next.js 타입 재생성
pnpm --filter erp dev  # 개발 서버 실행 시 자동 생성
```

### ESLint 에러

```bash
# ESLint 캐시 삭제
rm -rf node_modules/.cache

# 자동 수정
pnpm lint:fix
```

### Turborepo 캐시 문제

```bash
# Turborepo 캐시 삭제
rm -rf .turbo apps/*/.turbo packages/*/.turbo
```

## 프로젝트 관리

### 버전 관리

이 프로젝트는 Git으로 버전 관리됩니다.

```bash
# 변경사항 확인
git status

# 커밋
git add .
git commit -m "feat: 새 기능 추가"

# 푸시
git push
```

### CI/CD 및 배포

이 프로젝트는 Vercel에 배포되어 있습니다.

#### 배포된 환경
- **ERP 프로덕션**: [https://stay-management-sass-erp.vercel.app/](https://stay-management-sass-erp.vercel.app/)
- **Console 프로덕션**: [https://stay-management-sass-console.vercel.app/](https://stay-management-sass-console.vercel.app/)

#### Vercel 배포 설정

각 앱은 독립적으로 Vercel에 배포됩니다:

**ERP 앱 설정**:
- **Root Directory**: `apps/erp`
- **Build Command**: `cd ../.. && pnpm install && pnpm --filter erp build`
- **Output Directory**: `.next`
- **Framework**: Next.js

**Console 앱 설정**:
- **Root Directory**: `apps/console`
- **Build Command**: `cd ../.. && pnpm install && pnpm --filter console build`
- **Output Directory**: `.next`
- **Framework**: Next.js

#### 배포 프로세스

1. **자동 배포**: `main` 브랜치에 푸시하면 자동으로 배포됩니다.
2. **프리뷰 배포**: PR 생성 시 자동으로 프리뷰 환경이 생성됩니다.
3. **빌드 최적화**: Turborepo 캐싱을 활용하여 빌드 시간을 단축합니다.

#### 로컬에서 프로덕션 빌드 테스트

```bash
# 전체 빌드
pnpm build

# 프로덕션 모드로 실행
pnpm --filter erp start
pnpm --filter console start
```

## 라이선스

MIT License

## 참고 자료

- [Turborepo 문서](https://turbo.build/repo/docs)
- [Next.js 문서](https://nextjs.org/docs)
- [PNPM 문서](https://pnpm.io/)
- [Radix UI 문서](https://www.radix-ui.com/docs/primitives)
- [Tailwind CSS 문서](https://tailwindcss.com/docs)
- [TypeScript 문서](https://www.typescriptlang.org/docs/)
