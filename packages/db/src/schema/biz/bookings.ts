import { sql } from 'drizzle-orm';
import { bigserial, uuid, timestamp, index } from 'drizzle-orm/pg-core';
import { bizSchema } from '../../utils/schemas';
import { tenants } from '../org/tenants';
import { users } from '../iam/users';

export const bookings = bizSchema.table(
  'bookings',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id),
    ownerUserId: uuid('owner_user_id')
      .references(() => users.id, { onDelete: 'set null' }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (table) => ({
    tenant_id_idx: index('biz_bookings_tenant_id_index').on(table.tenantId),
    owner_user_id_idx: index('biz_bookings_owner_user_id_index').on(table.ownerUserId),
    tenant_owner_idx: index('biz_bookings_tenant_id_owner_user_id_index').on(
      table.tenantId,
      table.ownerUserId
    ),
  })
);

export type Booking = typeof bookings.$inferSelect;
export type NewBooking = typeof bookings.$inferInsert;
