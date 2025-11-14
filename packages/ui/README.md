# @repo/ui

공유 UI 컴포넌트 라이브러리 - Radix UI 기반

## 개요

이 패키지는 `erp`와 `console` 애플리케이션에서 공유하는 UI 컴포넌트를 제공합니다. Radix UI를 기반으로 하여 접근성이 뛰어나고 커스터마이징 가능한 컴포넌트를 제공합니다.

## 디자인 시스템 아키텍처

### Console 앱
- **스타일**: shadcn 기본 테마
- **사용 방법**: `@repo/ui`에서 컴포넌트를 import하여 사용
- **커스터마이징**: `tailwind.config.ts`에서 shadcn 스타일 확장

### ERP 앱
- **스타일**: 커스텀 브랜드 테마
- **사용 방법**: `@repo/ui`에서 동일한 컴포넌트 import
- **커스터마이징**: `tailwind.config.ts`와 `globals.css`에서 독립적인 테마 정의

## 설치된 의존성

```json
{
  "@radix-ui/react-slot": "^1.1.0",
  "class-variance-authority": "^0.7.1",
  "clsx": "^2.1.1",
  "tailwind-merge": "^2.5.5"
}
```

## 컴포넌트 추가 방법

### 1. Radix UI 의존성 추가

필요한 Radix UI 컴포넌트를 설치합니다:

```bash
# UI 패키지 디렉토리에서
pnpm add @radix-ui/react-dialog
pnpm add @radix-ui/react-dropdown-menu
pnpm add @radix-ui/react-select
# 등등...
```

### 2. 컴포넌트 파일 생성

`src/components/ui/` 디렉토리에 새 컴포넌트를 생성합니다:

```tsx
// src/components/ui/button.tsx
import * as React from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '../../lib/utils';

const buttonVariants = cva(
  'inline-flex items-center justify-center gap-2 whitespace-nowrap ' +
  'rounded-md text-sm font-medium transition-colors',
  {
    variants: {
      variant: {
        default: 'bg-primary text-primary-foreground hover:bg-primary/90',
        outline: 'border border-input bg-background hover:bg-accent',
        ghost: 'hover:bg-accent hover:text-accent-foreground',
      },
      size: {
        default: 'h-9 px-4 py-2',
        sm: 'h-8 px-3 text-xs',
        lg: 'h-10 px-8',
      },
    },
    defaultVariants: {
      variant: 'default',
      size: 'default',
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button';
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = 'Button';

export { Button, buttonVariants };
```

### 3. Export 추가

`src/index.ts`에 새 컴포넌트를 export합니다:

```typescript
export { Button, type ButtonProps } from './components/ui/button';
```

### 4. 앱에서 사용

```tsx
// apps/console/app/page.tsx 또는 apps/erp/app/page.tsx
import { Button } from '@repo/ui';

export default function Page() {
  return <Button>Click me</Button>;
}
```

## 추천 Radix UI 컴포넌트

다음은 일반적으로 사용되는 Radix UI 컴포넌트 목록입니다:

| 컴포넌트 | 패키지 | 사용 사례 |
|---------|--------|----------|
| Dialog | `@radix-ui/react-dialog` | 모달, 팝업 |
| Dropdown Menu | `@radix-ui/react-dropdown-menu` | 드롭다운 메뉴 |
| Select | `@radix-ui/react-select` | 셀렉트 박스 |
| Popover | `@radix-ui/react-popover` | 팝오버 |
| Tooltip | `@radix-ui/react-tooltip` | 툴팁 |
| Tabs | `@radix-ui/react-tabs` | 탭 |
| Accordion | `@radix-ui/react-accordion` | 아코디언 |
| Toast | `@radix-ui/react-toast` | 토스트 알림 |
| Switch | `@radix-ui/react-switch` | 토글 스위치 |
| Checkbox | `@radix-ui/react-checkbox` | 체크박스 |
| Radio Group | `@radix-ui/react-radio-group` | 라디오 버튼 |
| Label | `@radix-ui/react-label` | 레이블 |
| Avatar | `@radix-ui/react-avatar` | 아바타 |
| Separator | `@radix-ui/react-separator` | 구분선 |

## 참고 자료

- [Radix UI 공식 문서](https://www.radix-ui.com/docs/primitives/overview/introduction)
- [shadcn/ui 컴포넌트 예제](https://ui.shadcn.com/docs/components)
- [Class Variance Authority (CVA) 문서](https://cva.style/docs)
- [Tailwind CSS 문서](https://tailwindcss.com/docs)

## 개발 워크플로우

### 린팅
```bash
pnpm lint
```

### 자동 수정
```bash
pnpm lint:fix
```

### 타입 체크
```bash
pnpm type-check
```

## 베스트 프랙티스

1. **접근성 우선**: Radix UI는 기본적으로 접근성이 뛰어나므로 이를 유지하세요
2. **변형(Variants) 사용**: CVA를 사용하여 일관된 변형 시스템 구축
3. **타입 안전성**: 모든 컴포넌트에 TypeScript 타입 정의
4. **재사용성**: 작고 조합 가능한 컴포넌트 생성
5. **테마 독립성**: 컴포넌트는 CSS 변수에 의존하여 앱별 커스터마이징 허용

## 예제: 버튼 컴포넌트 사용

### Console 앱 (shadcn 스타일)
```tsx
import { Button } from '@repo/ui';

<Button>Default</Button>
<Button variant="outline">Outline</Button>
<Button variant="ghost">Ghost</Button>
```

### ERP 앱 (커스텀 스타일)
```tsx
import { Button } from '@repo/ui';

<Button className="bg-brand-500">Brand Button</Button>
<Button variant="outline" className="border-brand-500">Custom Outline</Button>
```

## 문제 해결

### 스타일이 적용되지 않는 경우
1. 앱의 `tailwind.config.ts`에 UI 패키지 경로가 포함되어 있는지 확인
2. `globals.css`에 CSS 변수가 정의되어 있는지 확인

### 타입 에러
1. `pnpm install`을 실행하여 의존성 재설치
2. `pnpm type-check`로 타입 에러 확인
