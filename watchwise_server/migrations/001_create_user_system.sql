-- Migration 001: Create User System for AIssist
-- Created: 2026-02-17
-- Purpose: Add authentication, subscriptions, and usage tracking

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'pro')),
    daily_usage_count INTEGER DEFAULT 0,
    last_usage_reset TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Create subscriptions table
CREATE TABLE IF NOT EXISTS subscriptions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tier VARCHAR(20) DEFAULT 'free' CHECK (tier IN ('free', 'premium', 'pro')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired', 'pending')),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE,
    payment_id TEXT,
    amount DECIMAL(10,2),
    currency VARCHAR(3) DEFAULT 'BRL',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create usage_logs table
CREATE TABLE IF NOT EXISTS usage_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    query TEXT NOT NULL,
    response TEXT,
    response_length INTEGER DEFAULT 0,
    processing_time_ms INTEGER DEFAULT 0,
    llm_model VARCHAR(100),
    estimated_cost DECIMAL(8,4),
    status VARCHAR(20) DEFAULT 'success' CHECK (status IN ('success', 'error', 'rate_limited')),
    error_message TEXT,
    user_agent TEXT DEFAULT 'AIssist-Web/1.0',
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_status ON subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_usage_logs_user_created ON usage_logs(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_logs_status ON usage_logs(status);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at 
    BEFORE UPDATE ON subscriptions 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert default admin user (password: admin123)
INSERT INTO users (email, password_hash, subscription_tier, is_active) 
VALUES (
    'admin@aissist.com',
    'ef797c8118f02dfb649607dd5d3f8c7623048c9c063d532cc95c5ed7a898a64f:IcJ1YmnxDLnU8C5nD0iBiQ',
    'pro',
    true
) ON CONFLICT (email) DO NOTHING;

-- Create admin subscription
INSERT INTO subscriptions (user_id, tier, status, start_date)
SELECT 
    u.id,
    'pro',
    'active',
    NOW()
FROM users u 
WHERE u.email = 'admin@aissist.com'
ON CONFLICT DO NOTHING;

-- Create view for user stats
CREATE OR REPLACE VIEW user_stats AS
SELECT 
    u.id,
    u.email,
    u.subscription_tier,
    u.daily_usage_count,
    u.created_at as user_since,
    s.tier as subscription_tier,
    s.status as subscription_status,
    s.end_date as subscription_expires,
    COUNT(ul.id) as total_queries,
    COUNT(CASE WHEN ul.created_at >= CURRENT_DATE THEN 1 END) as today_queries,
    COUNT(CASE WHEN ul.created_at >= DATE_TRUNC('week', CURRENT_DATE) THEN 1 END) as week_queries,
    AVG(ul.processing_time_ms) as avg_processing_time,
    MAX(ul.created_at) as last_query_at
FROM users u
LEFT JOIN subscriptions s ON u.id = s.user_id AND s.status = 'active'
LEFT JOIN usage_logs ul ON u.id = ul.user_id
WHERE u.is_active = true
GROUP BY u.id, u.email, u.subscription_tier, u.daily_usage_count, u.created_at, s.tier, s.status, s.end_date;

COMMENT ON TABLE users IS 'User accounts for AIssist platform';
COMMENT ON TABLE subscriptions IS 'User subscription plans and payment tracking';
COMMENT ON TABLE usage_logs IS 'AI query usage tracking and analytics';
COMMENT ON VIEW user_stats IS 'Comprehensive user statistics and usage metrics';

-- Grant permissions (adjust based on your database user)
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO aissist_user;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO aissist_user;