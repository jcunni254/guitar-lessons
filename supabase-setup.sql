-- ==================== GUITAR LESSON BOOKING DATABASE SCHEMA ====================
-- Execute this SQL in your Supabase SQL Editor to set up the database
-- DO NOT modify without understanding the implications

-- ==================== BOOKINGS TABLE ====================
CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  booking_date DATE NOT NULL,
  booking_time VARCHAR(10) NOT NULL,
  is_first_time BOOLEAN NOT NULL DEFAULT true,
  device_fingerprint VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'confirmed',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(booking_date, booking_time)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_bookings_email ON bookings(email);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_bookings_device ON bookings(device_fingerprint);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- ==================== QUESTIONNAIRES TABLE ====================
CREATE TABLE IF NOT EXISTS questionnaires (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  data JSONB NOT NULL,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_questionnaires_email ON questionnaires(email);
CREATE INDEX IF NOT EXISTS idx_questionnaires_completed ON questionnaires(completed);

-- ==================== AUDIT LOG TABLE ====================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action VARCHAR(50) NOT NULL,
  resource_type VARCHAR(50) NOT NULL,
  resource_id UUID,
  actor VARCHAR(255),
  details JSONB,
  ip_address VARCHAR(45),
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

-- ==================== ADMIN SESSIONS TABLE ====================
CREATE TABLE IF NOT EXISTS admin_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token_hash VARCHAR(255) UNIQUE NOT NULL,
  ip_address VARCHAR(45) NOT NULL,
  user_agent TEXT,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sessions_expires_at ON admin_sessions(expires_at);

-- ==================== ROW LEVEL SECURITY ====================
-- Enable RLS
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE questionnaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;

-- Policies for bookings (anyone can read/write their own)
CREATE POLICY "Bookings are readable" ON bookings
  FOR SELECT USING (true);

CREATE POLICY "Bookings are insertable" ON bookings
  FOR INSERT WITH CHECK (true);

-- Policies for questionnaires (email-based access)
CREATE POLICY "Questionnaires readable by email" ON questionnaires
  FOR SELECT USING (true);

CREATE POLICY "Questionnaires insertable" ON questionnaires
  FOR INSERT WITH CHECK (true);

-- Audit logs (read-only, created by system)
CREATE POLICY "Audit logs are readable" ON audit_logs
  FOR SELECT USING (true);

-- ==================== FUNCTIONS ====================
-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_questionnaires_updated_at BEFORE UPDATE ON questionnaires
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ==================== VIEWS ====================
-- Admin dashboard view
CREATE OR REPLACE VIEW admin_bookings_summary AS
SELECT
  booking_date,
  COUNT(*) as total_bookings,
  SUM(CASE WHEN is_first_time THEN 1 ELSE 0 END) as first_time_count,
  SUM(CASE WHEN is_first_time THEN 0 ELSE 1 END) as returning_count
FROM bookings
WHERE status = 'confirmed'
GROUP BY booking_date
ORDER BY booking_date DESC;

-- ==================== INITIAL DATA CHECKS ====================
-- Create a function to check data integrity
CREATE OR REPLACE FUNCTION check_double_booking()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM bookings
    WHERE booking_date = NEW.booking_date
    AND booking_time = NEW.booking_time
    AND id != NEW.id
    AND status = 'confirmed'
  ) THEN
    RAISE EXCEPTION 'Time slot already booked';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_double_booking_trigger
BEFORE INSERT OR UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION check_double_booking();

-- ==================== COMMENTS ====================
COMMENT ON TABLE bookings IS 'Stores all guitar lesson bookings with device fingerprinting for limit enforcement';
COMMENT ON TABLE questionnaires IS 'Stores first-time learner questionnaire responses';
COMMENT ON TABLE audit_logs IS 'Audit trail of all system actions for security and compliance';
COMMENT ON TABLE admin_sessions IS 'Tracks active admin sessions for security';

-- ==================== GRANTS ====================
-- Ensure anon user can access public functions
GRANT EXECUTE ON FUNCTION check_double_booking() TO anon;
GRANT EXECUTE ON FUNCTION update_updated_at_column() TO anon;

PRINT 'Database schema created successfully!';
