import { sql } from 'drizzle-orm';
import { uuid, text, bigint, timestamp, unique, index } from 'drizzle-orm/pg-core';
import { orgSchema } from '../../utils/schemas';
import { tenantStatusTypes } from '../ref/tenant-status-types';

export const tenants = orgSchema.table(
  'tenants',
  {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    slug: text('slug').notNull(),
    name: text('name').notNull(),
    status: bigint('status', { mode: 'number' })
      .notNull()
      .references(() => tenantStatusTypes.id),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (table) => ({
    slug_unique: unique('org_tenants_slug_unique').on(table.slug),
    status_idx: index('org_tenants_status_index').on(table.status),
  })
);

export type Tenant = typeof tenants.$inferSelect;
export type NewTenant = typeof tenants.$inferInsert;
