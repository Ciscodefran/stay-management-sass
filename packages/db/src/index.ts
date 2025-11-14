/**
 * @stay/db - Schema-only entry point
 *
 * ✅ SAFE FOR ALL APPS including React Native
 *
 * This file exports ONLY:
 * - Table schema definitions
 * - TypeScript types (User, Booking, etc.)
 * - Type utilities
 *
 * ❌ Does NOT export:
 * - Database connection/instance
 * - Drizzle driver initialization
 * - Node.js-specific dependencies
 *
 * Usage:
 *   import { users, type User } from '@stay/db';
 *   import type { Booking } from '@stay/db';
 */

export * from './schema';
