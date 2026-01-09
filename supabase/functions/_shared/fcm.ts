// supabase/functions/_shared/fcm.ts
import * as jose from "https://deno.land/x/jose@v4.15.5/index.ts";

type ExtraData = Record<string, string>;

type SendResult = {
  sent: number;
  failed: number;
};

function must<T>(v: T | undefined | null, name: string): T {
  if (v === undefined || v === null || (typeof v === "string" && v.trim() === "")) {
    throw new Error(`Missing ${name}`);
  }
  return v;
}

/**
 * Supports BOTH:
 * - FCM_SERVICE_ACCOUNT_JSON_B64  (recommended, what you currently have in Supabase Secrets)
 * - FCM_SERVICE_ACCOUNT_JSON      (raw JSON string)
 */
function readServiceAccountJson(): string {
  const b64 = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON_B64");
  if (b64 && b64.trim().length > 0) {
    try {
      // atob exists in Edge runtime (browser-like)
      return atob(b64);
    } catch {
      throw new Error("FCM_SERVICE_ACCOUNT_JSON_B64 is not valid base64");
    }
  }

  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (raw && raw.trim().length > 0) return raw;

  throw new Error("Missing FCM_SERVICE_ACCOUNT_JSON_B64 (or FCM_SERVICE_ACCOUNT_JSON) env var");
}

function parseServiceAccount() {
  const raw = readServiceAccountJson();

  let obj: any;
  try {
    obj = JSON.parse(raw);
  } catch {
    throw new Error("Firebase service account JSON is not valid JSON");
  }

  const project_id = must(obj.project_id, "service_account.project_id");
  const client_email = must(obj.client_email, "service_account.client_email");
  let private_key = must(obj.private_key, "service_account.private_key");

  // If env pasted with escaped newlines
  private_key = private_key.replace(/\\n/g, "\n");

  return { project_id, client_email, private_key };
}

async function getAccessToken(): Promise<{ token: string; projectId: string }> {
  const { project_id, client_email, private_key } = parseServiceAccount();

  const now = Math.floor(Date.now() / 1000);
  const jwt = await new jose.SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(client_email)
    .setSubject(client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 60 * 50)
    .sign(await jose.importPKCS8(private_key, "RS256"));

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }).toString(),
  });

  const json = await resp.json().catch(() => ({}));
  if (!resp.ok) {
    console.error("OAuth token error:", json);
    throw new Error(`OAuth token request failed: ${JSON.stringify(json)}`);
  }

  const token = must(json.access_token, "oauth.access_token") as string;
  return { token, projectId: project_id };
}

export async function sendFcmToTokens(
  tokens: string[],
  title: string,
  body: string,
  data: ExtraData = {},
): Promise<SendResult> {
  const cleanTokens = (tokens ?? []).filter((t) => typeof t === "string" && t.length > 0);
  if (cleanTokens.length === 0) return { sent: 0, failed: 0 };

  const { token: accessToken, projectId } = await getAccessToken();

  let sent = 0;
  let failed = 0;

  for (const t of cleanTokens) {
    const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    const payload = {
      message: {
        token: t,
        notification: { title, body },
        data,
      },
    };

    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (res.ok) {
      sent++;
    } else {
      failed++;
      const errJson = await res.json().catch(() => ({}));
      console.error("FCM send failed:", errJson);
    }
  }

  return { sent, failed };
}
