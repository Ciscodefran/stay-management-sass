import { sql } from 'drizzle-orm';
import { uuid, text, timestamp } from 'drizzle-orm/pg-core';
import { iamSchema } from '../../utils/schemas';

export const users = iamSchema.table('users', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  status: text('status', { enum: ['active', 'suspended', 'archived'] })
    .notNull()
    .default('active'),
  createdAt: timestamp('created_at', { withTimezone: true })
    .notNull()
    .default(sql`now()`),
});

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
