/**
 * Common type utilities for database schema
 */

export type InferSelectModel<T> = T extends { $inferSelect: infer S } ? S : never;
export type InferInsertModel<T> = T extends { $inferInsert: infer I } ? I : never;
