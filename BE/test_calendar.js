import dotenv from 'dotenv';
import { google } from 'googleapis';

dotenv.config();

const test = async () => {
  try {
    const auth = new google.auth.GoogleAuth({
      credentials: {
        client_email: process.env.GOOGLE_SERVICE_ACCOUNT_EMAIL,
        private_key: process.env.GOOGLE_PRIVATE_KEY.replace(/\\n/g, '\n'),
      },
      scopes: ['https://www.googleapis.com/auth/calendar'],
    });

    const calendar = google.calendar({ version: "v3", auth });

    const event = {
      summary: "Test Event",
      start: { dateTime: new Date().toISOString() },
      end: { dateTime: new Date(Date.now() + 3600000).toISOString() },
      conferenceData: {
        createRequest: {
          requestId: `meet-${Date.now()}`,
          conferenceSolutionKey: { type: "hangoutsMeet" },
        },
      },
    };

    console.log("Inserting event...");
    const res = await calendar.events.insert({
      calendarId: process.env.GOOGLE_CALENDAR_ID || "primary",
      resource: event,
      conferenceDataVersion: 1,
    });

    console.log("Success:", res.data.hangoutLink);
  } catch (err) {
    console.error("Error occurred:");
    console.error(err.message);
  }
};

test();
