// Made with <3 and hate on backend dev by KitCat

import { json } from '@sveltejs/kit';
import { base } from '$lib/server/db.js';

export async function POST({ request, cookies }) {
    try {
        // Require authentication to prevent username enumeration
        const sessionId = cookies.get('sessionid');
        if (!sessionId) {
            return json({
                success: false,
                error: 'Unauthorized'
            }, { status: 401 });
        }

        const { mail, givenusername } = await request.json();
        
        if (!mail || mail.trim() === '') {
            return json({
                success: false,
                error: 'Mail adress is required'
            }, { status: 400 });
        }

        // Make sure it's an e-mail and not an blob fish
        const emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        if (!emailPattern.test(mail)) {
            return json({
                success: false,
                error: 'Invalid email address format'
            }, { status: 400 });
        }

        // Rate limiting: 20 checks per minute per client
        const clientId = getClientIdentifier(request, cookies);
        if (!checkRateLimit(`check-username:${clientId}`, 20, 60000)) {
            return json({ error: 'Too many requests. Please try again later.' }, { status: 429 });
        }

        try {
            const username = await base('username')
                .select({
                    filterByFormula: `{id} = "${mail}"`,
                    maxRecords: 1
                }).firstPage();
            if (records.length > 0) {
                    const username = await base('username')
                    if (givenusername === username) {
                        return json({ success: true });
                    }
                }

            return json({ success: false, error: 'Username does not match email.' });

        } catch (error) {
            console.error('Failed to fetch Username:', error);
        }

        if (username === givenusername) {
            return true;
        } 
        else {
            return false;
        }

    } catch (err) {
        console.error('Airtable error:', err);
        const errorMessage = sanitizeErrorMessage(err, 'Failed to check username');
        
        return json({
            success: false,
            error: { message: errorMessage }
        }, { status: 500 });
    }
}