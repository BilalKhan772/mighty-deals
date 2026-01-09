import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { sendFcmToTokens } from "../_shared/fcm.ts";

type Body = { spin_id: string };

function json(status: number, data: Record<string, unknown>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
    },
  });
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

serve(async (req: Request) => {
  try {
    if (req.method === "OPTIONS") return json(200, { ok: true });
    if (req.method !== "POST") return json(405, { error: "METHOD_NOT_ALLOWED" });

    // safer body parse
    let bodyObj: Partial<Body> = {};
    try {
      bodyObj = (await req.json()) as Partial<Body>;
    } catch {
      return json(400, { error: "INVALID_JSON_BODY" });
    }

    const spinId = (bodyObj?.spin_id ?? "").trim();
    if (!spinId) return json(400, { error: "SPIN_ID_REQUIRED" });

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceKey) {
      return json(500, {
        error: "SERVER_MISCONFIG",
        details: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY",
      });
    }

    const sb = createClient(supabaseUrl, serviceKey);

    // 1) Get spin city + status
    const { data: spin, error: spinErr } = await sb
      .from("spins")
      .select("id, city, status")
      .eq("id", spinId)
      .single();

    if (spinErr || !spin) {
      return json(404, { error: "SPIN_NOT_FOUND", details: spinErr?.message, spin_id: spinId });
    }

    const city = (spin.city ?? "").trim();
    if (!city) return json(400, { error: "SPIN_CITY_EMPTY", spin_id: spinId });

    // Only notify published
    if (spin.status !== "published") {
      return json(200, {
        ok: true,
        skipped: true,
        reason: "SPIN_NOT_PUBLISHED",
        status: spin.status,
        city,
        spin_id: spinId,
      });
    }

    // 2) Tokens for that city
    const { data: rows, error: tokErr } = await sb
      .from("push_tokens")
      .select("token")
      .eq("city", city);

    if (tokErr) {
      return json(500, { error: "TOKENS_FETCH_FAILED", details: tokErr.message, city });
    }

    const tokens = (rows ?? [])
      .map((r: any) => r?.token)
      .filter((t: any) => typeof t === "string" && t.length > 0);

    if (tokens.length === 0) {
      return json(200, { ok: true, sent: 0, failed: 0, city, note: "NO_TOKENS", spin_id: spinId });
    }

    const title = "🔥 New Mighty Spin";
    const msg = `New spin available in ${city}. Join now!`;

    // 3) Send push (FCM v1)
    let totalSent = 0;
    let totalFailed = 0;

    for (const part of chunk(tokens, 200)) {
      const res = await sendFcmToTokens(part, title, msg, {
        type: "SPIN_PUBLISHED",
        spin_id: spinId,
        city,
      });

      totalSent += res.sent;
      totalFailed += res.failed;
    }

    return json(200, {
      ok: true,
      city,
      spin_id: spinId,
      sent: totalSent,
      failed: totalFailed,
    });
  } catch (e) {
    console.error("notify_spin_published crash:", e);
    return json(500, { error: "SERVER_ERROR", details: String(e?.message ?? e) });
  }
});
