import { sql } from 'drizzle-orm';
import { uuid, text, timestamp, index, primaryKey } from 'drizzle-orm/pg-core';
import { iamSchema } from '../../utils/schemas';
import { users } from './users';

export const userIdentities = iamSchema.table(
  'user_identities',
  {
    issuer: text('issuer', { enum: ['clerk', 'supabase'] })
      .notNull()
      .default('supabase'),
    subject: text('subject').notNull(),
    internalUserId: uuid('internal_user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }),
  },
  (table) => ({
    pk: primaryKey({ columns: [table.issuer, table.subject] }),
    internal_user_id_idx: index('iam_user_identities_internal_user_id_index').on(
      table.internalUserId
    ),
  })
);

export type UserIdentity = typeof userIdentities.$inferSelect;
export type NewUserIdentity = typeof userIdentities.$inferInsert;
