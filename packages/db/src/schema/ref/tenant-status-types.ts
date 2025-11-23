import { bigserial, varchar, text } from 'drizzle-orm/pg-core';

import { refSchema } from '../../lib/schemas';

export const tenantStatusTypes = refSchema.table('tenant_status_types', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  code: varchar('code', { length: 255 }).notNull().unique(),
  name: text('name').notNull(),
  description: text('description').notNull(),
});

export type TenantStatusType = typeof tenantStatusTypes.$inferSelect;
export type NewTenantStatusType = typeof tenantStatusTypes.$inferInsert;
