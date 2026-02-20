--
-- Class User as table users
--
CREATE TABLE "users" (
  "id" serial PRIMARY KEY,
  "email" text NOT NULL,
  "passwordHash" text NOT NULL,
  "subscriptionTier" text NOT NULL DEFAULT 'Free',
  "dailyUsageCount" integer NOT NULL DEFAULT 0,
  "dailyUsageResetDate" timestamp without time zone NOT NULL DEFAULT CURRENT_DATE,
  "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index for email lookups
CREATE UNIQUE INDEX "users_email_idx" ON "users" USING btree ("email");

-- Index for subscription tier
CREATE INDEX "users_subscription_tier_idx" ON "users" USING btree ("subscriptionTier");

--
-- Class Subscription as table subscriptions  
--
CREATE TABLE "subscriptions" (
  "id" serial PRIMARY KEY,
  "userId" integer NOT NULL,
  "tier" text NOT NULL,
  "status" text NOT NULL DEFAULT 'active',
  "paymentProvider" text,
  "paymentId" text,
  "amountCents" integer,
  "currency" text DEFAULT 'BRL',
  "startedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt" timestamp without time zone,
  "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Foreign key constraint
ALTER TABLE ONLY "subscriptions"
  ADD CONSTRAINT "subscriptions_fk_0"
  FOREIGN KEY("userId")
  REFERENCES "users"("id")
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- Index for user lookups
CREATE INDEX "subscriptions_userId_idx" ON "subscriptions" USING btree ("userId");

--
-- Class UsageLog as table usage_logs
--
CREATE TABLE "usage_logs" (
  "id" serial PRIMARY KEY,
  "userId" integer NOT NULL,
  "queryText" text NOT NULL,
  "responseText" text,
  "processingTimeMs" integer,
  "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "modelUsed" text,
  "tokensUsed" integer,
  "costCents" integer
);

-- Foreign key constraint
ALTER TABLE ONLY "usage_logs"
  ADD CONSTRAINT "usage_logs_fk_0"
  FOREIGN KEY("userId")
  REFERENCES "users"("id")
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

-- Index for user lookups
CREATE INDEX "usage_logs_userId_idx" ON "usage_logs" USING btree ("userId");

-- Index for date-based queries
CREATE INDEX "usage_logs_createdAt_idx" ON "usage_logs" USING btree ("createdAt");

--
-- Trigger function for updated_at
--
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON "users" 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at 
    BEFORE UPDATE ON "subscriptions" 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert admin user for testing (password: admin123 hashed with bcrypt)
INSERT INTO "users" ("email", "passwordHash", "subscriptionTier") 
VALUES ('admin@aissist.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewUFCxFwxdDZxAjG', 'Pro')
ON CONFLICT ("email") DO NOTHING;

-- Create sample subscription for admin user
INSERT INTO "subscriptions" ("userId", "tier", "status", "amountCents", "currency")
SELECT 
    u."id", 
    'Pro', 
    'active', 
    3990, 
    'BRL'
FROM "users" u 
WHERE u."email" = 'admin@aissist.com';