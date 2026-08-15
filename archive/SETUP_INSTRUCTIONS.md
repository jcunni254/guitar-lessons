# Guitar Lesson Booking Website - Setup Instructions

## Overview
This is a fully functional guitar lesson booking system with:
- Interactive calendar and time slot selection
- Automatic booking confirmation emails
- First-time student questionnaire
- Clean, professional design matching your branding

## Files Included
1. **index.html** - Main booking page with calendar and scheduling
2. **questionnaire.html** - First-time student intake form
3. **SETUP_INSTRUCTIONS.md** - This file

## Quick Start (No Backend - Local Testing)

The website works entirely in your browser using localStorage. No backend server needed to test:

1. Open `index.html` in your web browser
2. Select a date and time
3. Enter your name and email
4. Click "Book Now"
5. View the confirmation popup
6. The booking is saved locally in your browser

**Note:** Email sending and questionnaire submissions are saved to localStorage. To make these features production-ready, you'll need to set up a backend.

---

## Production Setup (With Email & Database)

### Option 1: Node.js/Express Backend (Recommended)

#### Step 1: Install Dependencies
```bash
npm init -y
npm install express dotenv nodemailer cors body-parser
```

#### Step 2: Create `server.js`
```javascript
const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

// Configure email
const transporter = nodemailer.createTransport({
  service: 'gmail', // or your email service
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD
  }
});

// Send confirmation email
app.post('/api/send-email', async (req, res) => {
  const { name, email, date, time, questionnaireLink } = req.body;

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Guitar Lesson Booking Confirmation - Jacob Cunningham',
    html: `
      <h2>Thank You for Booking!</h2>
      <p>Hi ${name},</p>
      <p>Your guitar lesson has been confirmed!</p>
      
      <h3>Booking Details:</h3>
      <ul>
        <li><strong>Date:</strong> ${date}</li>
        <li><strong>Time:</strong> ${time}</li>
        <li><strong>Instructor:</strong> Jacob Cunningham</li>
      </ul>

      <p>Please arrive 5 minutes early and have your guitar ready.</p>

      <p style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #ccc;">
        <strong>First time booking?</strong><br>
        <a href="${questionnaireLink}" style="color: #2d5f7a; font-weight: bold;">Click here to fill out the student questionnaire</a>
        <br>This helps me prepare for your first lesson!
      </p>

      <p style="color: #999; font-size: 0.9em; margin-top: 20px;">
        If you need to reschedule or have questions, please reply to this email.
      </p>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    res.json({ success: true, message: 'Email sent successfully' });
  } catch (error) {
    console.error('Email error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Save questionnaire
app.post('/api/questionnaire', async (req, res) => {
  const data = req.body;
  
  // Save to database or file
  console.log('Questionnaire received:', data);
  
  try {
    // TODO: Save to your database here
    res.json({ success: true, message: 'Questionnaire saved' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
```

#### Step 3: Create `.env` file
```
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
PORT=3000
```

**For Gmail:**
1. Enable 2-factor authentication on your Google Account
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Use that password in .env (NOT your regular Gmail password)

#### Step 4: Update `index.html` Email Sending

In `index.html`, find the `sendConfirmationEmail` function and replace it with:

```javascript
async function sendConfirmationEmail(name, email, bookingDetails) {
  const questionnaireLink = `${window.location.origin}/questionnaire.html?email=${encodeURIComponent(email)}`;

  try {
    const response = await fetch('/api/send-email', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: name,
        email: email,
        date: bookingDetails.split(' at ')[0],
        time: bookingDetails.split(' at ')[1],
        questionnaireLink: questionnaireLink
      })
    });

    const result = await response.json();
    if (result.success) {
      console.log('Confirmation email sent');
    } else {
      showStatus('Failed to send email. Please try again.', 'error');
    }
  } catch (error) {
    console.error('Error sending email:', error);
  }
}
```

#### Step 5: Run the Server
```bash
node server.js
```

---

### Option 2: Firebase (Easiest Cloud Solution)

#### Step 1: Create Firebase Project
1. Go to https://firebase.google.com
2. Create a new project
3. Enable Firestore Database
4. Enable Cloud Functions

#### Step 2: Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
firebase init
```

#### Step 3: Create Cloud Function for Emails

Create `functions/index.js`:
```javascript
const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: functions.config().email.user,
    pass: functions.config().email.password
  }
});

exports.sendConfirmationEmail = functions.https.onCall(async (data, context) => {
  const { name, email, date, time } = data;

  const mailOptions = {
    from: functions.config().email.user,
    to: email,
    subject: 'Guitar Lesson Booking Confirmation',
    html: `
      <h2>Thank You for Booking!</h2>
      <p>Hi ${name},</p>
      <p><strong>Date:</strong> ${date}<br><strong>Time:</strong> ${time}</p>
      <p><a href="${data.questionnaireLink}">Click here to fill out the questionnaire</a></p>
    `
  };

  return transporter.sendMail(mailOptions);
});

exports.saveQuestionnaire = functions.https.onCall(async (data, context) => {
  const db = admin.firestore();
  await db.collection('questionnaires').add(data);
  return { success: true };
});
```

#### Step 4: Deploy
```bash
firebase deploy
```

---

## Email Service Recommendations

| Service | Cost | Ease | Best For |
|---------|------|------|----------|
| **Gmail (Nodemailer)** | Free | Easy | Small volume (personal) |
| **SendGrid** | Free tier available | Easy | Growing business |
| **Mailgun** | Free tier available | Medium | High volume |
| **AWS SES** | Pay per email | Medium | Large scale |
| **Firebase** | Free tier available | Medium | Already using Firebase |

---

## Hosting Options

### Static Hosting (No Backend Needed)
- **Netlify** (Free) - Drag & drop, auto-deploys from Git
- **Vercel** (Free) - Great for serverless functions
- **GitHub Pages** (Free) - Static only, no backend
- **AWS S3** (Very cheap) - Highly scalable

### With Backend
- **Heroku** (Free tier ended, ~$7+/month now)
- **Railway** ($5/month starting)
- **Render** (Free tier available)
- **DigitalOcean App Platform** ($12/month)

---

## Database Options (for storing questionnaires & bookings)

### Easy Options
- **Firebase Firestore** (Free tier generous)
- **MongoDB Atlas** (Free tier available)
- **Supabase** (Firebase alternative, Free tier)

### Spreadsheet Alternative
- **Google Sheets API** - Save directly to a shared Google Sheet (easiest non-technical option)

---

## Customization Guide

### Change Time Slots
In `index.html`, find the `TIME_SLOTS` array:
```javascript
const TIME_SLOTS = [
  '9:00 AM', '9:30 AM', '10:00 AM', // etc
];
```

Modify to your available hours.

### Change Colors
The main colors are:
- Primary: `#2d5f7a` (teal blue)
- Accent: `#1a3a4a` (dark)

Search for these hex codes in the CSS to customize.

### Pricing (Optional)
To add pricing, modify the booking details section in `index.html`:
```javascript
<div class="pricing-info">
  <p>Lesson Price: $XX per hour</p>
  <p>Total: $XX</p>
</div>
```

---

## Testing Checklist

- [ ] Calendar navigates correctly
- [ ] Past dates are disabled
- [ ] Bookings persist when page reloads
- [ ] Booked slots show as unavailable
- [ ] Confirmation modal displays correctly
- [ ] Email sends successfully
- [ ] Questionnaire form validates all required fields
- [ ] Questionnaire saves data
- [ ] Mobile view is responsive

---

## Troubleshooting

### Emails not sending?
- Check email/password in .env
- Enable "Less secure app access" (Gmail) or use App Passwords
- Check spam folder
- Review server logs for errors

### Bookings not persisting?
- Check browser localStorage is enabled
- Try a different browser
- Clear browser cache and reload

### Calendar not showing correctly?
- Check browser console (F12) for JavaScript errors
- Ensure all files are in the same directory

---

## Support Resources

- **Nodemailer Docs**: https://nodemailer.com/
- **Firebase Setup**: https://firebase.google.com/docs
- **SendGrid**: https://sendgrid.com/docs/
- **CORS Issues**: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS

---

## Next Steps

1. **Test locally** - Open index.html in browser, book a lesson
2. **Choose your backend** - Pick email service and hosting
3. **Deploy** - Push to Netlify, Vercel, or your server
4. **Add your details** - Update email in code to yours
5. **Go live!** - Share booking link with students

Enjoy your booking system! 🎸
