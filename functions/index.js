const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { GoogleAuth } = require('google-auth-library');

// Initialize the Admin SDK
try {
  admin.initializeApp();
} catch (e) {
  // Initialization may be called multiple times in some environments
}

// Startup diagnostic: log admin app info and environment variables helpful for messaging
try {
  const app = admin.app();
  console.log('Functions startup: admin.apps.length=', admin.apps.length);
  console.log('Functions startup: admin app name=', app.name);
  console.log('Functions startup: admin app projectId=', app.options && app.options.projectId);
  console.log('Functions startup: GCLOUD_PROJECT=', process.env.GCLOUD_PROJECT);
  try {
    const cfg = process.env.FIREBASE_CONFIG;
    if (cfg) console.log('Functions startup: FIREBASE_CONFIG (truncated)=', cfg.slice(0, 200));
  } catch (e) {
    console.log('Functions startup: failed to read FIREBASE_CONFIG', e);
  }
} catch (e) {
  console.log('Functions startup: admin.app() not available yet', e);
}

/**
 * Helper: send a notification payload to a set of FCM tokens and clean up
 * invalid tokens returned by the send operation.
 */
async function sendToTokens(tokens, payload) {
  if (!tokens || tokens.length === 0) {
    return { successCount: 0 };
  }

  // Diagnostic: log tokens count and a truncated preview (avoid logging full tokens in prod)
  console.log(`sendToTokens: sending to ${tokens.length} token(s)`);
  try {
    const preview = tokens.slice(0, 5).map(t => (t || '').slice(0, 30) + ((t && t.length > 30) ? '...' : ''));
    console.log('sendToTokens: token preview:', preview);

    // Use FCM v1 REST API with OAuth to avoid Admin SDK endpoint issues.
    const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/firebase.messaging'] });
    const client = await auth.getClient();
    const at = await client.getAccessToken();
    const accessToken = at && at.token ? at.token : at;

    const projectId = (admin.app() && admin.app().options && admin.app().options.projectId) || process.env.GCLOUD_PROJECT;
    if (!projectId) throw new Error('Missing project id for FCM v1 calls');
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    let successCount = 0;
    let failureCount = 0;
    const tokensToRemove = [];

    // Helper to send one message to a token using FCM v1
    const sendOne = async (token) => {
      const body = {
        message: {
          token: token,
          notification: payload.notification || undefined,
          data: payload.data || undefined,
        },
      };

      try {
        const resp = await fetch(url, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(body),
        });
        const text = await resp.text();
        if (resp.ok) {
          successCount++;
          return { ok: true };
        }

        // Non-200 response: attempt to parse JSON error
        let j = null;
        try {
          j = JSON.parse(text);
        } catch (e) {
          // ignore
        }
        const status = j && j.error && j.error.status ? j.error.status : null;
        console.log('sendToTokens: fcm v1 error', resp.status, status, text.slice(0, 1000));
        failureCount++;
        // Mark tokens for removal on specific FCM errors
        if (status === 'UNREGISTERED' || status === 'NOT_FOUND' || status === 'INVALID_ARGUMENT') {
          tokensToRemove.push(token);
        }
        return { ok: false, error: j || text };
      } catch (err) {
        console.error('sendToTokens: http error while sending to token', err);
        failureCount++;
        return { ok: false, error: err };
      }
    };

    // Throttle concurrent requests to FCM to avoid rate limits
    const concurrency = 20;
    for (let i = 0; i < tokens.length; i += concurrency) {
      const batch = tokens.slice(i, i + concurrency);
      await Promise.all(batch.map(t => sendOne(t)));
    }

    // Cleanup invalid tokens found
    if (tokensToRemove.length > 0) {
      console.log('sendToTokens: removing invalid tokens count=', tokensToRemove.length);
      const batch = admin.firestore().batch();
      for (const token of tokensToRemove) {
        const q = await admin.firestore().collectionGroup('fcmTokens').where('__name__', '==', token).get();
        q.docs.forEach(d => batch.delete(d.ref));
      }
      await batch.commit();
    }

    return { successCount, failureCount, tokensToRemove };
  } catch (err) {
    console.error('sendToTokens: unexpected error sending to tokens', err, { stack: err && err.stack });
    throw err;
  }
}

// Helper: verify a configured debug secret for HTTP debug endpoints
function verifyDebugSecret(req, res) {
  try {
    const cfg = functions.config();
    const expected = cfg && cfg.debug && cfg.debug.secret ? cfg.debug.secret : null;
    if (!expected) {
      res.status(500).json({ error: 'debug secret not configured' });
      return false;
    }
    const provided = (req.query && req.query.secret) || (req.body && req.body.secret) || '';
    if (String(provided) !== String(expected)) {
      res.status(403).json({ error: 'forbidden' });
      return false;
    }
    return true;
  } catch (e) {
    console.error('verifyDebugSecret error', e);
    res.status(500).json({ error: 'server error' });
    return false;
  }
}


/**
 * Firestore trigger: when a message is created, send a push notification to the
 * intended recipient. The message document is expected to contain one of the
 * recipient identifiers: `toUid`, `recipientId`, or `receiverId`. If none are
 * present, the function will try to fall back to `hijoId`-based topics or skip.
 */
exports.onMensajeCreated = functions.firestore
  .document('mensajes/{messageId}')
  .onCreate(async (snap, context) => {
    const msg = snap.data() || {};
    const messageId = context.params.messageId;

    // Try multiple possible recipient fields
    const toUid = msg.toUid || msg.recipientId || msg.receiverId || null;

    // Build a user-friendly body
    const preview = (msg.text || msg.content || msg.message || '')
      .toString()
      .slice(0, 220);

    const payload = {
      notification: {
        title: 'Nuevo mensaje',
        body: preview || 'Has recibido un nuevo mensaje',
      },
      data: {
        screen: 'mensajeria',
        messageId: messageId,
        hijoId: msg.hijoId ? String(msg.hijoId) : '',
      },
      android: {
        priority: 'high',
        notification: { sound: 'default' },
      },
      apns: {
        payload: {
          aps: { sound: 'default' }
        }
      }
    };

    try {
      // Basic validation: ensure a sender is present
      const senderId = (msg.senderId || msg.fromUid || msg.sender || '').toString();
      if (!senderId) {
        console.log('onMensajeCreated: message missing senderId, skipping notification', messageId);
        return null;
      }

      // If an explicit toUid was provided, prefer direct send to that user
      if (toUid) {
        const tokensSnap = await admin.firestore().collection('users').doc(toUid).collection('fcmTokens').get();
        const tokens = tokensSnap.docs.map(d => d.id);
        if (tokens.length === 0) {
          console.log('No FCM tokens for user', toUid);
          return null;
        }
        await sendToTokens(tokens, payload);
        console.log('Notification sent to user tokens for', toUid);
        return null;
      }

      // Otherwise: if hijoId exists, send to the child's parents (progenitores)
      if (msg.hijoId) {
        const hijoId = String(msg.hijoId);
        const hijoRef = admin.firestore().collection('hijos').doc(hijoId);
        const hijoSnap = await hijoRef.get();
        if (!hijoSnap.exists) {
          console.log('onMensajeCreated: hijo doc not found for hijoId=', hijoId);
          return null;
        }
        const hijoData = hijoSnap.data() || {};
        const progenitores = Array.isArray(hijoData.progenitores) ? hijoData.progenitores : (hijoData.progenitores || []);

        // Security: validate sender belongs to the child's progenitores
        if (!progenitores.includes(senderId)) {
          console.log('onMensajeCreated: sender is not an authorized progenitor for hijoId=', hijoId, 'sender=', senderId);
          return null;
        }

        // Send to all progenitores except the sender
        const recipients = progenitores.filter(pid => pid && pid !== senderId);
        if (recipients.length === 0) {
          console.log('onMensajeCreated: no recipients (progenitores) to notify for hijoId=', hijoId);
          return null;
        }

        // For each recipient, collect tokens and send
        for (const rid of recipients) {
          try {
            const tokensSnap = await admin.firestore().collection('users').doc(rid).collection('fcmTokens').get();
            const tokens = tokensSnap.docs.map(d => d.id);
            if (!tokens || tokens.length === 0) {
              console.log('onMensajeCreated: no tokens for recipient', rid);
              continue;
            }
            await sendToTokens(tokens, payload);
            console.log('onMensajeCreated: notification sent to recipient', rid, 'tokensCount=', tokens.length);
          } catch (innerErr) {
            console.error('onMensajeCreated: failed sending to recipient', rid, innerErr);
          }
        }

        return null;
      }

      console.log('No recipient found for message', messageId);
      return null;
    } catch (err) {
      console.error('Error sending notification for message', messageId, err);
      throw err;
    }
  });


/**
 * Callable function: sendNotification
 * Allows testing sending arbitrary notifications to a specific user UID or
 * a list of tokens. Expected data shape:
 * { toUid?: string, tokens?: string[], title?: string, body?: string, data?: object }
 */
exports.sendNotification = functions.https.onCall(async (data, context) => {
  console.log('sendNotification: called. data present?', !!data, 'auth present?', !!context.auth);

  // Protect this callable: require an authenticated caller. In production you
  // may want to require a custom claim (e.g. admin) or restrict this via IAM.
  if (!context.auth) {
    console.log('sendNotification: rejected unauthenticated caller');
    throw new functions.https.HttpsError('permission-denied', 'Authentication required to call this function');
  }

  if (!data) {
    console.log('sendNotification: missing data payload');
    throw new functions.https.HttpsError('invalid-argument', 'No data provided');
  }

  console.log('sendNotification: incoming data (truncated):', JSON.stringify(data).slice(0, 1000));

  const title = data.title || 'Notificación prueba';
  const body = data.body || 'Mensaje de prueba desde Cloud Functions';

  const payload = {
    notification: { title, body },
    data: Object.assign({}, data.data || {}),
    // Note: platform-specific fields may be rejected by some Admin endpoints; keep them light
  };

  try {
    if (data.toUid) {
      console.log('sendNotification: sending to toUid=', data.toUid);
      const tokensSnap = await admin.firestore().collection('users').doc(data.toUid).collection('fcmTokens').get();
      const tokens = tokensSnap.docs.map(d => d.id);
      console.log('sendNotification: found tokens count=', tokens.length);
      const resp = await sendToTokens(tokens, payload);
      console.log('sendNotification: sendToTokens completed. resp summary:', {
        successCount: resp && resp.successCount !== undefined ? resp.successCount : null,
        failureCount: resp && resp.failureCount !== undefined ? resp.failureCount : null,
      });
      return { success: true, result: resp };
    }

    if (Array.isArray(data.tokens) && data.tokens.length > 0) {
      console.log('sendNotification: sending to explicit tokens array length=', data.tokens.length);
      const resp = await sendToTokens(data.tokens, payload);
      console.log('sendNotification: explicit tokens send completed. resp summary:', {
        successCount: resp && resp.successCount !== undefined ? resp.successCount : null,
        failureCount: resp && resp.failureCount !== undefined ? resp.failureCount : null,
      });
      return { success: true, result: resp };
    }

    throw new functions.https.HttpsError('invalid-argument', 'Provide `toUid` or `tokens`');
  } catch (err) {
    console.error('sendNotification error', err, { stack: err && err.stack });
    throw new functions.https.HttpsError('internal', 'Failed to send notification: ' + (err && err.message ? err.message : String(err)));
  }
});


// Debug helper (temporary): HTTP endpoint to list FCM tokens stored under a user
// Usage: GET /debugGetTokens?uid=<USER_UID>
exports.debugGetTokens = functions.https.onRequest(async (req, res) => {
  try {
    // Require debug secret to avoid exposing tokens publicly
    if (!verifyDebugSecret(req, res)) return;
    const uid = (req.query.uid || req.body && req.body.uid || '').toString();
    if (!uid) {
      res.status(400).json({ error: 'missing uid' });
      return;
    }

    const snap = await admin.firestore().collection('users').doc(uid).collection('fcmTokens').get();
    const tokens = snap.docs.map(d => ({ id: d.id, data: d.data() }));
    res.json({ uid, count: tokens.length, tokens });
  } catch (err) {
    console.error('debugGetTokens error', err);
    res.status(500).json({ error: String(err) });
  }
});


// Debug helper: attempt to call the FCM v1 REST API directly using an OAuth access
// token obtained via the Google Auth library. This can reveal the raw HTTP
// response when Admin SDK calls fail (useful to debug 404/500 returned by FCM).
// Usage: POST/GET /debugSendToken?token=<FCM_TOKEN>
exports.debugSendToken = functions.https.onRequest(async (req, res) => {
  try {
    // Require debug secret to avoid exposing token send
    if (!verifyDebugSecret(req, res)) return;
    const token = (req.query.token || (req.body && req.body.token) || '').toString();
    if (!token) return res.status(400).json({ error: 'missing token' });

    const projectId = (admin.app() && admin.app().options && admin.app().options.projectId) || process.env.GCLOUD_PROJECT;
    if (!projectId) return res.status(500).json({ error: 'missing project id' });

    const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/firebase.messaging'] });
    const client = await auth.getClient();
    const at = await client.getAccessToken();
    const accessToken = at && at.token ? at.token : at;

    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const body = {
      message: {
        token: token,
        notification: { title: 'Debug FCM', body: 'Mensaje de prueba (debugSendToken)' }
      }
    };

    console.log('debugSendToken: POST', url, 'payload preview:', JSON.stringify(body).slice(0, 1000));

    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    });

    const text = await resp.text();
    console.log('debugSendToken: response status=', resp.status, 'body=', text.slice(0, 2000));
    res.status(resp.status).send({ status: resp.status, body: text });
  } catch (err) {
    console.error('debugSendToken error', err);
    res.status(500).json({ error: String(err) });
  }
});
