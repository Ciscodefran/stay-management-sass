import { ReactQueryProvider } from '@repo/health';
import type { Metadata } from 'next';

import './globals.css';

export const metadata: Metadata = {
  title: 'ERP App',
  description: 'Stay Management ERP Application',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ko">
      <body>
        <ReactQueryProvider>{children}</ReactQueryProvider>
      </body>
    </html>
  );
}
