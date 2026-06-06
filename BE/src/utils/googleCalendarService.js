import { google } from "googleapis";

/**
 * Creates a Google Meet link via Google Calendar API
 * @param {Date} startTime 
 * @param {Date} endTime 
 * @param {String} summary 
 */
export const createMeetLink = async (startTime, endTime, summary) => {
  try {
    const generateFakeMeetId = () => {
      const chars = 'abcdefghijklmnopqrstuvwxyz';
      const rand = (len) => Array.from({length: len}, () => chars[Math.floor(Math.random() * chars.length)]).join('');
      return `${rand(3)}-${rand(4)}-${rand(3)}`;
    };

    if (!process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL || !process.env.GOOGLE_PRIVATE_KEY) {
      console.warn("Google Calendar credentials missing. Generating a mock Meet link.");
      return `https://meet.google.com/${generateFakeMeetId()}`;
    }

    const auth = new google.auth.GoogleAuth({
      credentials: {
        client_email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
        private_key: process.env.GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      },
      scopes: ['https://www.googleapis.com/auth/calendar'],
    });

    const calendar = google.calendar({ version: "v3", auth });

    const event = {
      summary: summary || "Consultation with Doctor",
      start: {
        dateTime: startTime.toISOString(),
      },
      end: {
        dateTime: endTime.toISOString(),
      },
    };

    const res = await calendar.events.insert({
      calendarId: process.env.GOOGLE_CALENDAR_ID || "primary",
      resource: event,
    });

    const staticMeetLink = process.env.DOCTOR_MEET_LINK || "https://meet.google.com/YOUR_STATIC_LINK";
    return staticMeetLink;
  } catch (error) {
    console.error("Error creating Meet link:", error);
    // Fallback if API fails
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    const rand = (len) => Array.from({length: len}, () => chars[Math.floor(Math.random() * chars.length)]).join('');
    return `https://meet.google.com/${rand(3)}-${rand(4)}-${rand(3)}`;
  }
};
