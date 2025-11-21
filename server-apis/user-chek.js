// Milkilog api -checks if user exists
// Build by KitCat

import { json } from '@sveltejs/kit';
import { sanitizeErrorMessage } from '$lib/server/security.js';
import { getUserInfoBySessionId } from '$lib/server/auth.js';
import { createDevlog, getTodayDevlogs } from '$lib/server/devlogs.js';
import { getUserProjectsByEmail } from '$lib/server/projects.js';
import { fetchTodayProjects } from '$lib/server/hackatime.js';
import { base } from '$lib/server/db.js';

const MAX_VIDEO_SIZE = 10 * 1024 * 1024; // 10MB

// POST - Create user devlog
export async function POST({ locals, cookies, request }) {
    try {
        if (!locals.user) {
            return json({ error: 'Unauthorized' }, { status: 401 });
        }

        const userInfo = await getUserInfoBySessionId(cookies.get('sessionid'));

        // Check if the user exists using a function
        const userExists = await checkIfUserExists(userInfo.email); // Assuming email is used to find the user

        if (!userExists) {
            return json({ error: 'User does not exist.' }, { status: 404 });
        }

        // Get form data from request
        const formData = await request.formData();
        const title = formData.get('title');
        const description = formData.get('description');
        const selectedProjects = formData.get('selectedProjects');

        if (!title || typeof title !== 'string' || !title.trim()) {
            return json({ error: 'Please write a title!' }, { status: 400 });
        }

        if (!description || typeof description !== 'string' || !description.trim()) {
            return json({ error: 'You also need a description!' }, { status: 400 });
        }

        if (!selectedProjects || typeof selectedProjects !== 'string' || !selectedProjects.trim()) {
            return json({ error: 'Please select at least one project!' }, { status: 400 });
        }

        // Remaining logic to handle hour calculations and devlog creation...
    } catch (error) {
        console.error('Error creating devlog:', error);
        return json({
            error: sanitizeErrorMessage(error, 'Failed to create devlog')
        }, { status: 500 });
    }
}

// Function to check if a user exists
async function checkIfUserExists(email) {
    try {
        const result = await base('Users') // Modify the table name to match yours
            .select({
                filterByFormula: `{Email} = "${email}"`
            })
            .firstPage();

        return result.length > 0; // Return true if user exists
    } catch (error) {
        console.error('Error checking user existence:', error);
        return false; // If there's an error, assume the user does not exist
    }
}