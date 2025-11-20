CREATE TABLE IF NOT EXISTS "biz"."bookings" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"tenant_id" uuid NOT NULL,
	"owner_user_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "iam"."users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"status" text DEFAULT 'active' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "iam"."user_identities" (
	"issuer" text DEFAULT 'supabase' NOT NULL,
	"subject" text NOT NULL,
	"internal_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"last_seen_at" timestamp with time zone,
	CONSTRAINT "user_identities_issuer_subject_pk" PRIMARY KEY("issuer","subject")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "iam"."role_types" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"code" varchar(255) DEFAULT 'member' NOT NULL,
	"name" text NOT NULL,
	"description" text NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "iam_role_types_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "iam"."user_tenants" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"internal_user_id" uuid NOT NULL,
	"tenant_id" uuid NOT NULL,
	"role_type_id" bigint NOT NULL,
	"is_default" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "iam_user_tenants_user_tenant_unique" UNIQUE("internal_user_id","tenant_id")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "iam"."session_contexts" (
	"session_id" text PRIMARY KEY NOT NULL,
	"internal_user_id" uuid NOT NULL,
	"client_id" text DEFAULT 'app' NOT NULL,
	"active_tenant_id" uuid NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "iam_session_contexts_client_id_check" CHECK ("iam"."session_contexts"."client_id" IN ('erp', 'app', 'bot'))
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "org"."tenants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"slug" text NOT NULL,
	"name" text NOT NULL,
	"status" bigint NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "org_tenants_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE IF NOT EXISTS "ref"."tenant_status_types" (
	"id" bigserial PRIMARY KEY NOT NULL,
	"code" varchar(255) NOT NULL,
	"name" text NOT NULL,
	"description" text NOT NULL,
	CONSTRAINT "tenant_status_types_code_unique" UNIQUE("code")
);
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "biz"."bookings" ADD CONSTRAINT "bookings_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "org"."tenants"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "biz"."bookings" ADD CONSTRAINT "bookings_owner_user_id_users_id_fk" FOREIGN KEY ("owner_user_id") REFERENCES "iam"."users"("id") ON DELETE set null ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "iam"."user_identities" ADD CONSTRAINT "user_identities_internal_user_id_users_id_fk" FOREIGN KEY ("internal_user_id") REFERENCES "iam"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "iam"."user_tenants" ADD CONSTRAINT "user_tenants_internal_user_id_users_id_fk" FOREIGN KEY ("internal_user_id") REFERENCES "iam"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "iam"."user_tenants" ADD CONSTRAINT "user_tenants_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "org"."tenants"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "iam"."user_tenants" ADD CONSTRAINT "user_tenants_role_type_id_role_types_id_fk" FOREIGN KEY ("role_type_id") REFERENCES "iam"."role_types"("id") ON DELETE restrict ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "iam"."session_contexts" ADD CONSTRAINT "session_contexts_internal_user_id_users_id_fk" FOREIGN KEY ("internal_user_id") REFERENCES "iam"."users"("id") ON DELETE cascade ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "iam"."session_contexts" ADD CONSTRAINT "session_contexts_active_tenant_id_tenants_id_fk" FOREIGN KEY ("active_tenant_id") REFERENCES "org"."tenants"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
DO $$ BEGIN
 ALTER TABLE "org"."tenants" ADD CONSTRAINT "tenants_status_tenant_status_types_id_fk" FOREIGN KEY ("status") REFERENCES "ref"."tenant_status_types"("id") ON DELETE no action ON UPDATE no action;
EXCEPTION
 WHEN duplicate_object THEN null;
END $$;
--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "biz_bookings_tenant_id_index" ON "biz"."bookings" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "biz_bookings_owner_user_id_index" ON "biz"."bookings" USING btree ("owner_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "biz_bookings_tenant_id_owner_user_id_index" ON "biz"."bookings" USING btree ("tenant_id","owner_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "iam_user_identities_internal_user_id_index" ON "iam"."user_identities" USING btree ("internal_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "iam_user_tenants_internal_user_id_tenant_id_index" ON "iam"."user_tenants" USING btree ("internal_user_id","tenant_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "iam_user_tenants_role_type_id_index" ON "iam"."user_tenants" USING btree ("role_type_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "iam_user_tenants_tenant_id_role_type_id_index" ON "iam"."user_tenants" USING btree ("tenant_id","role_type_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "iam_session_contexts_internal_user_id_index" ON "iam"."session_contexts" USING btree ("internal_user_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "iam_session_contexts_active_tenant_id_index" ON "iam"."session_contexts" USING btree ("active_tenant_id");--> statement-breakpoint
CREATE INDEX IF NOT EXISTS "org_tenants_status_index" ON "org"."tenants" USING btree ("status");