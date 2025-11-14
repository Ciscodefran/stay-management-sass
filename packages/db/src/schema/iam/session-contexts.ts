import { sql } from 'drizzle-orm';
import { text, uuid, timestamp, index, check } from 'drizzle-orm/pg-core';
import { iamSchema } from '../../utils/schemas';
import { users } from './users';
import { tenants } from '../org/tenants';

export const sessionContexts = iamSchema.table(
  'session_contexts',
  {
    sessionId: text('session_id').primaryKey(),
    internalUserId: uuid('internal_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    clientId: text('client_id', { enum: ['erp', 'app', 'bot'] })
      .notNull()
      .default('app'),
    activeTenantId: uuid('active_tenant_id')
      .notNull()
      .references(() => tenants.id),
    updatedAt: timestamp('updated_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (table) => ({
    internal_user_id_idx: index('iam_session_contexts_internal_user_id_index').on(
      table.internalUserId
    ),
    active_tenant_id_idx: index('iam_session_contexts_active_tenant_id_index').on(
      table.activeTenantId
    ),
    client_id_check: check('iam_session_contexts_client_id_check', sql`${table.clientId} IN ('erp', 'app', 'bot')`),
  })
);

export type SessionContext = typeof sessionContexts.$inferSelect;
export type NewSessionContext = typeof sessionContexts.$inferInsert;
