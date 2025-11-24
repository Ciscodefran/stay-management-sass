import { ReactQueryProvider } from '@repo/health';
import type { Metadata } from 'next';

import './globals.css';

export const metadata: Metadata = {
  title: 'Console App',
  description: 'Stay Management Console Application',
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
