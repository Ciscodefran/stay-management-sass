import { sql } from 'drizzle-orm';
import { bigserial, uuid, bigint, boolean, timestamp, index, unique } from 'drizzle-orm/pg-core';
import { iamSchema } from '../../utils/schemas';
import { users } from './users';
import { roleTypes } from './role-types';
import { tenants } from '../org/tenants';

export const userTenants = iamSchema.table(
  'user_tenants',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    internalUserId: uuid('internal_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'cascade' }),
    roleTypeId: bigint('role_type_id', { mode: 'number' })
      .notNull()
      .references(() => roleTypes.id, { onDelete: 'restrict' }),
    isDefault: boolean('is_default').notNull().default(false),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (table) => ({
    user_tenant_unique: unique('iam_user_tenants_user_tenant_unique').on(
      table.internalUserId,
      table.tenantId
    ),
    user_tenant_idx: index('iam_user_tenants_internal_user_id_tenant_id_index').on(
      table.internalUserId,
      table.tenantId
    ),
    role_type_id_idx: index('iam_user_tenants_role_type_id_index').on(
      table.roleTypeId
    ),
    tenant_role_idx: index('iam_user_tenants_tenant_id_role_type_id_index').on(
      table.tenantId,
      table.roleTypeId
    ),
  })
);

export type UserTenant = typeof userTenants.$inferSelect;
export type NewUserTenant = typeof userTenants.$inferInsert;
