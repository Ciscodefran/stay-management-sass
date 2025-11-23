import { sql } from 'drizzle-orm';
import { bigserial, varchar, text, boolean, timestamp, unique } from 'drizzle-orm/pg-core';

import { iamSchema } from '../../lib/schemas';

export const roleTypes = iamSchema.table(
  'role_types',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    code: varchar('code', { length: 255 })
      .notNull()
      .default('member'),
    name: text('name').notNull(),
    description: text('description').notNull(),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true })
      .notNull()
      .default(sql`now()`),
  },
  (table) => ({
    code_unique: unique('iam_role_types_code_unique').on(table.code),
  }),
);

export type RoleType = typeof roleTypes.$inferSelect;
export type NewRoleType = typeof roleTypes.$inferInsert;
