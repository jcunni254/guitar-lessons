import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import morgan from 'morgan';
import compression from 'compression';
import { createClient } from '@supabase/supabase-js';
import { Redis } from '@upstash/redis';
import nodemailer from 'nodemailer';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { body, validationResult, param } from 'express-validator';
import { v4 as uuidv4 } from 'uuid';
import 'dotenv/config';

// ==================== CONFIGURATION ====================
const app = express();
const PORT = process.env.PORT || 3000;

// Environment Variables Validation
const requiredEnvVars = [
  'SUPABASE_URL',
  'SUPABASE_ANON_KEY',
  'UPSTASH_REDIS_REST_URL',
  'UPSTASH_REDIS_REST_TOKEN',
  'JWT_SECRET',
  'ADMIN_PASSWORD_HASH',
  'EMAIL_USER',
  'EMAIL_PASSWORD',
  'FRONTEND_URL'
];

requiredEnvVars.forEach(envVar => {
  if (!process.env[envVar]) {
    console.error(`❌ Missing required environment variable: ${envVar}`);
    process.exit(1);
  }
});

// ==================== MIDDLEWARE ====================

// Security Headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", 'data:', 'https:'],
      connectSrc: ["'self'", process.env.FRONTEND_URL],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
  frameguard: { action: 'deny' },
  noSniff: true,
  xssFilter: true,
}));

// CORS Configuration
const corsOptions = {
  origin: process.env.FRONTEND_URL.split(','),
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 3600,
};
app.use(cors(corsOptions));

// Body Parser & Compression
app.use(compression());
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ limit: '10kb', extended: true }));

// Logging
app.use(morgan(':remote-addr - :remote-user [:date[clf]] ":method :url HTTP/:http-version" :status :res[content-length] ":referrer" ":user-agent" - :response-time ms'));

// ==================== DATABASE & CACHE INITIALIZATION ====================

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

// Email Configuration
const emailTransporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

// ==================== RATE LIMITING ====================

// Booking endpoint - stricter limits
const bookingLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5, // 5 requests per minute
  message: 'Too many booking attempts, please try again later',
  standardHeaders: true,
  legacyHeaders: false,
  // NOTE: uses the default in-memory store. The previous rate-limit-redis store
  // was never declared in package.json and is incompatible with @upstash/redis
  // (it requires a node-redis/ioredis `sendCommand`). Revisit with
  // @upstash/ratelimit if we scale past a single instance.
});

// General API limiter
const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per 15 minutes
  standardHeaders: true,
  legacyHeaders: false,
});

// Login limiter
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 login attempts per 15 minutes
  skipSuccessfulRequests: true,
});

app.use('/api/', apiLimiter);
app.use('/api/auth/login', loginLimiter);

// ==================== AUTHENTICATION ====================

const verifyAdminToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.admin = decoded;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

// ==================== ROUTES ====================

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'operational',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Admin Login
app.post('/api/auth/login', [
  body('password').trim().notEmpty().withMessage('Password required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { password } = req.body;
    const isValid = await bcrypt.compare(password, process.env.ADMIN_PASSWORD_HASH);

    if (!isValid) {
      // Log failed attempt
      await redis.incr('failed_login_attempts');
      console.warn('⚠️ Failed login attempt');
      return res.status(401).json({ error: 'Invalid password' });
    }

    // Reset failed attempts on success
    await redis.del('failed_login_attempts');

    const token = jwt.sign(
      { role: 'admin', exp: Math.floor(Date.now() / 1000) + (60 * 60) }, // 1 hour
      process.env.JWT_SECRET
    );

    res.json({
      token,
      message: 'Authentication successful'
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Book a Lesson
app.post('/api/bookings', bookingLimiter, [
  body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Valid name required'),
  body('email').isEmail().withMessage('Valid email required'),
  body('phone').optional().isMobilePhone().withMessage('Valid phone number'),
  body('date').isISO8601().withMessage('Valid date required'),
  body('time').matches(/^\d{1,2}:\d{2}\s(AM|PM)$/).withMessage('Valid time required'),
  body('isFirstTime').isBoolean().withMessage('Learner type required'),
  body('deviceFingerprint').trim().notEmpty().withMessage('Device fingerprint required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, phone, date, time, isFirstTime, deviceFingerprint } = req.body;

    // Check device booking limit
    const deviceBookings = await redis.get(`bookings:device:${deviceFingerprint}`);
    const currentBookings = deviceBookings ? parseInt(deviceBookings) : 0;

    if (currentBookings >= 2) {
      return res.status(429).json({
        error: 'Device booking limit reached',
        message: 'You have already booked 2 lessons. Contact the instructor for more bookings.'
      });
    }

    // Check if time slot is available
    const slotKey = `slot:${date}:${time}`;
    const isSlotTaken = await redis.get(slotKey);

    if (isSlotTaken) {
      return res.status(409).json({ error: 'Time slot already booked' });
    }

    // Create booking in Supabase
    const bookingId = uuidv4();
    const { data, error } = await supabase
      .from('bookings')
      .insert([{
        id: bookingId,
        name: sanitizeInput(name),
        email: email.toLowerCase(),
        phone: phone || null,
        booking_date: date,
        booking_time: time,
        is_first_time: isFirstTime,
        device_fingerprint: deviceFingerprint,
        status: 'confirmed',
        created_at: new Date().toISOString(),
      }]);

    if (error) {
      console.error('Supabase insert error:', error);
      return res.status(500).json({ error: 'Failed to create booking' });
    }

    // Lock the time slot in Redis (24 hours)
    await redis.set(slotKey, 'booked', { ex: 86400 });

    // Increment device booking count
    await redis.incr(`bookings:device:${deviceFingerprint}`);

    // Send confirmation email
    await sendBookingConfirmationEmail(name, email, date, time, isFirstTime, bookingId);

    // Log booking
    console.log(`✅ Booking created: ${bookingId} for ${name} on ${date} at ${time}`);

    res.status(201).json({
      success: true,
      bookingId,
      message: 'Booking confirmed! Check your email for details.',
    });
  } catch (error) {
    console.error('Booking error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Change Booking
app.put('/api/bookings/:id/change', [
  param('id').isUUID().withMessage('Valid booking ID required'),
  body('newDate').isISO8601().withMessage('Valid date required'),
  body('newTime').matches(/^\d{1,2}:\d{2}\s(AM|PM)$/).withMessage('Valid time required'),
  body('deviceFingerprint').trim().notEmpty().withMessage('Device verification required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;
    const { newDate, newTime, deviceFingerprint } = req.body;

    // Fetch original booking
    const { data: booking, error: fetchError } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError || !booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    // Verify device matches
    if (booking.device_fingerprint !== deviceFingerprint) {
      console.warn(`⚠️ Unauthorized change attempt for booking ${id}`);
      return res.status(403).json({ error: 'Unauthorized: Device mismatch' });
    }

    // Check if new slot is available
    const newSlotKey = `slot:${newDate}:${newTime}`;
    const isSlotTaken = await redis.get(newSlotKey);

    if (isSlotTaken) {
      return res.status(409).json({ error: 'New time slot already booked' });
    }

    // Update booking
    const { error: updateError } = await supabase
      .from('bookings')
      .update({
        booking_date: newDate,
        booking_time: newTime,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id);

    if (updateError) {
      console.error('Update error:', error);
      return res.status(500).json({ error: 'Failed to update booking' });
    }

    // Update Redis cache
    const oldSlotKey = `slot:${booking.booking_date}:${booking.booking_time}`;
    await redis.del(oldSlotKey);
    await redis.set(newSlotKey, 'booked', { ex: 86400 });

    console.log(`✅ Booking ${id} rescheduled to ${newDate} at ${newTime}`);

    res.json({
      success: true,
      message: 'Booking rescheduled successfully',
      newDate,
      newTime
    });
  } catch (error) {
    console.error('Change booking error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get All Bookings (Admin Only)
app.get('/api/admin/bookings', verifyAdminToken, async (req, res) => {
  try {
    const { data: bookings, error } = await supabase
      .from('bookings')
      .select('*')
      .order('booking_date', { ascending: true });

    if (error) {
      return res.status(500).json({ error: 'Failed to fetch bookings' });
    }

    // Group by date
    const groupedBookings = {};
    bookings.forEach(booking => {
      if (!groupedBookings[booking.booking_date]) {
        groupedBookings[booking.booking_date] = [];
      }
      groupedBookings[booking.booking_date].push(booking);
    });

    res.json({
      total: bookings.length,
      bookings: groupedBookings,
    });
  } catch (error) {
    console.error('Fetch error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Get Booking Details (Admin Only)
app.get('/api/admin/bookings/:id', verifyAdminToken, [
  param('id').isUUID().withMessage('Valid booking ID required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { id } = req.params;

    const { data: booking, error } = await supabase
      .from('bookings')
      .select('*')
      .eq('id', id)
      .single();

    if (error || !booking) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    res.json(booking);
  } catch (error) {
    console.error('Fetch error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Save Questionnaire (First-time learners)
app.post('/api/questionnaires', [
  body('email').isEmail().withMessage('Valid email required'),
  body('name').trim().isLength({ min: 2, max: 100 }).withMessage('Valid name required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, name, ...questionnaireData } = req.body;
    const questionnaireId = uuidv4();

    const { error } = await supabase
      .from('questionnaires')
      .insert([{
        id: questionnaireId,
        email: email.toLowerCase(),
        name: sanitizeInput(name),
        data: JSON.stringify(questionnaireData),
        created_at: new Date().toISOString(),
      }]);

    if (error) {
      console.error('Questionnaire insert error:', error);
      return res.status(500).json({ error: 'Failed to save questionnaire' });
    }

    console.log(`✅ Questionnaire saved for ${email}`);

    res.status(201).json({
      success: true,
      questionnaireId,
      message: 'Questionnaire saved successfully',
    });
  } catch (error) {
    console.error('Questionnaire error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Check Slot Availability
app.post('/api/check-availability', [
  body('date').isISO8601().withMessage('Valid date required'),
  body('time').matches(/^\d{1,2}:\d{2}\s(AM|PM)$/).withMessage('Valid time required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { date, time } = req.body;
    const slotKey = `slot:${date}:${time}`;
    const isAvailable = !(await redis.get(slotKey));

    res.json({ available: isAvailable });
  } catch (error) {
    console.error('Availability check error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// Error Handling
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(err.status || 500).json({
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// ==================== HELPER FUNCTIONS ====================

function sanitizeInput(input) {
  return input
    .replace(/[<>]/g, '')
    .trim()
    .substring(0, 200);
}

async function sendBookingConfirmationEmail(name, email, date, time, isFirstTime, bookingId) {
  try {
    const questionnaireLink = isFirstTime
      ? `${process.env.FRONTEND_URL}/questionnaire.html?email=${encodeURIComponent(email)}&booking=${encodeURIComponent(`${date} at ${time}`)}`
      : null;

    const emailBody = isFirstTime ? `
      <h2>Thank You for Booking, ${name}!</h2>
      <p>Your guitar lesson has been confirmed!</p>
      <h3>Booking Details:</h3>
      <ul>
        <li><strong>Date:</strong> ${date}</li>
        <li><strong>Time:</strong> ${time}</li>
        <li><strong>Instructor:</strong> Jacob Cunningham</li>
      </ul>
      <p><strong>First time booking?</strong><br>
      <a href="${questionnaireLink}">Click here to complete your student profile</a></p>
      <p style="color: #999; font-size: 0.9em; margin-top: 20px;">
        If you need to reschedule, visit: ${process.env.FRONTEND_URL}
      </p>
    ` : `
      <h2>Booking Confirmed, ${name}!</h2>
      <p>Your lesson is scheduled for:</p>
      <h3>${date} at ${time}</h3>
      <p>See you then!</p>
    `;

    await emailTransporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Guitar Lesson Booking Confirmation - Jacob Cunningham',
      html: emailBody,
    });

    console.log(`📧 Confirmation email sent to ${email}`);
  } catch (error) {
    console.error('Email sending error:', error);
  }
}

// ==================== SERVER START ====================

app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════╗
║     🎸 Guitar Lesson Booking Platform - Server       ║
║     Environment: ${process.env.NODE_ENV || 'production'}
║     Port: ${PORT}
║     Status: ✅ Running
╚═══════════════════════════════════════════════════════╝
  `);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

export default app;
