-- ==============================================================================
-- BATANG KALYE - SUPABASE MASTER SERVER & MATCHMAKING SCHEMA
-- ==============================================================================
-- Run this script in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new

-- 1. Create the Lobbies table
CREATE TABLE IF NOT EXISTS public.lobbies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    host_name TEXT NOT NULL,
    address TEXT NOT NULL,
    port INT NOT NULL DEFAULT 7777,
    player_count INT NOT NULL DEFAULT 1,
    max_players INT NOT NULL DEFAULT 8,
    game_mode TEXT NOT NULL DEFAULT 'Pasa-Taya',
    is_started BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Index for high-performance querying
CREATE INDEX IF NOT EXISTS idx_lobbies_active 
ON public.lobbies (is_started, updated_at DESC);

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.lobbies ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist (for idempotent execution)
DROP POLICY IF EXISTS "Allow public read" ON public.lobbies;
DROP POLICY IF EXISTS "Allow public insert" ON public.lobbies;
DROP POLICY IF EXISTS "Allow public update" ON public.lobbies;
DROP POLICY IF EXISTS "Allow public delete" ON public.lobbies;

-- 4. Open Policies for anonymous game matchmaking (Read, Create, Heartbeat, Delete)
CREATE POLICY "Allow public read" 
ON public.lobbies FOR SELECT 
TO anon, authenticated 
USING (true);

CREATE POLICY "Allow public insert" 
ON public.lobbies FOR INSERT 
TO anon, authenticated 
WITH CHECK (true);

CREATE POLICY "Allow public update" 
ON public.lobbies FOR UPDATE 
TO anon, authenticated 
USING (true);

CREATE POLICY "Allow public delete" 
ON public.lobbies FOR DELETE 
TO anon, authenticated 
USING (true);

-- 5. Auto-cleanup function for stale / crashed host lobbies (older than 2 minutes)
CREATE OR REPLACE FUNCTION public.clean_stale_lobbies() 
RETURNS void AS $$
BEGIN
    DELETE FROM public.lobbies 
    WHERE updated_at < now() - interval '2 minutes';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Trigger to automatically update updated_at timestamp on updates
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_lobbies_updated_at ON public.lobbies;
CREATE TRIGGER trigger_set_lobbies_updated_at
BEFORE UPDATE ON public.lobbies
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Confirmation message
SELECT 'Batang Kalye lobbies table and RLS policies successfully initialized!' AS status;
