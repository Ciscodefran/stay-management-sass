import { pgSchema } from 'drizzle-orm/pg-core';

/**
 * PostgreSQL schema definitions for multi-schema database organization
 */

export const iamSchema = pgSchema('iam');
export const orgSchema = pgSchema('org');
export const bizSchema = pgSchema('biz');
export const refSchema = pgSchema('ref');
export const pubSchema = pgSchema('pub');
