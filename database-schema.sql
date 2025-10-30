-- =============================================
-- Muroro Livestock Management Database Schema
-- Fixed for Nhost with proper auth.uid() support
-- =============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- Core Tables
-- =============================================

-- Animals table for individual animal tracking (with photos)
CREATE TABLE animals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('beef-cattle', 'steer', 'sheep', 'goat')),
    name TEXT NOT NULL,
    breed TEXT,
    birthdate DATE,
    photo_id TEXT, -- References storage.files
    health_status TEXT DEFAULT 'healthy' CHECK (health_status IN ('healthy', 'sick', 'injured', 'treated')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Poultry table for group management (no individual photos)
CREATE TABLE poultry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('roadrunner-chicken', 'layer-chicken', 'broiler', 'other')),
    group_name TEXT,
    bird_count INTEGER NOT NULL DEFAULT 1 CHECK (bird_count > 0),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- Row Level Security (RLS) Policies - FIXED
-- =============================================

-- Enable RLS on all tables
ALTER TABLE animals ENABLE ROW LEVEL SECURITY;
ALTER TABLE poultry ENABLE ROW LEVEL SECURITY;

-- Animals policies - FIXED auth.uid() usage
CREATE POLICY "Users can view own animals" ON animals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own animals" ON animals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own animals" ON animals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own animals" ON animals
    FOR DELETE USING (auth.uid() = user_id);

-- Poultry policies - FIXED auth.uid() usage
CREATE POLICY "Users can view own poultry" ON poultry
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own poultry" ON poultry
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own poultry" ON poultry
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own poultry" ON poultry
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================
-- Indexes for Performance
-- =============================================

-- Animals indexes
CREATE INDEX idx_animals_user_id ON animals(user_id);
CREATE INDEX idx_animals_type ON animals(type);
CREATE INDEX idx_animals_health_status ON animals(health_status);

-- Poultry indexes
CREATE INDEX idx_poultry_user_id ON poultry(user_id);
CREATE INDEX idx_poultry_type ON poultry(type);

-- =============================================
-- Database Functions
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_animals_updated_at BEFORE UPDATE ON animals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_poultry_updated_at BEFORE UPDATE ON poultry
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();