import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { sendFcmToTokens } from "../_shared/fcm.ts";

type Body = {
  spin_id: string;
  forced_unique_code?: string | null; // e.g. "#1022"
};

function json(status: number, data: Record<string, unknown>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      // optional CORS (safe)
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
    if (req.method !== "POST") return json(405, { error: "Method not allowed" });

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    if (!supabaseUrl || !anonKey || !serviceKey) {
      return json(500, { error: "Missing env vars" });
    }

    // 1) Client with anon + Authorization header (your current pattern)
    const authHeader = req.headers.get("Authorization") ?? "";
    const client = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Ensure caller is authenticated
    const { data: authData, error: authErr } = await client.auth.getUser();
    if (authErr || !authData?.user) return json(401, { error: "Unauthorized" });

    const body = (await req.json()) as Body;
    const spinId = (body.spin_id ?? "").trim();
    const forced = body.forced_unique_code?.trim() || null;

    if (!spinId) return json(400, { error: "SPIN_ID_REQUIRED" });

    // 2) Run RPC (winner selection + DB updates)
    const { data, error } = await client.rpc("rpc_start_spin_pick_winner", {
      spin_id: spinId,
      forced_unique_code: forced,
    });

    if (error) {
      const m = error.message ?? "RPC_ERROR";
      if (m.includes("FORBIDDEN")) return json(403, { error: "FORBIDDEN" });
      if (m.includes("NO_PARTICIPANTS")) return json(400, { error: "NO_PARTICIPANTS" });
      if (m.includes("FORCED_USER_NOT_FOUND")) return json(400, { error: "FORCED_USER_NOT_FOUND" });
      if (m.includes("FORCED_USER_NOT_PARTICIPANT")) return json(400, { error: "FORCED_USER_NOT_PARTICIPANT" });
      return json(500, { error: "RPC_ERROR", details: m });
    }

    const row = Array.isArray(data) ? data[0] : data;
    const winnerUserId = row?.winner_user_id;
    const winnerCode = row?.winner_code as string | undefined;

    // 3) Push to all tokens of the spin city (service role client)
    const admin = createClient(supabaseUrl, serviceKey);

    // Fetch spin city
    const { data: spin, error: spinErr } = await admin
      .from("spins")
      .select("id, city")
      .eq("id", spinId)
      .single();

    // If push part fails, DO NOT fail the main winner response
    if (spinErr || !spin?.city) {
      return json(200, {
        ok: true,
        winner_user_id: winnerUserId,
        winner_code: winnerCode,
        push: { ok: false, reason: "SPIN_CITY_FETCH_FAILED", details: spinErr?.message },
      });
    }

    // Tokens for that city
    const { data: tokRows, error: tokErr } = await admin
      .from("push_tokens")
      .select("token")
      .eq("city", spin.city);

    if (tokErr) {
      return json(200, {
        ok: true,
        winner_user_id: winnerUserId,
        winner_code: winnerCode,
        push: { ok: false, reason: "TOKENS_FETCH_FAILED", details: tokErr.message },
      });
    }

    const tokens = (tokRows ?? []).map((r: any) => r.token).filter(Boolean);

    let sent = 0;
    if (tokens.length > 0) {
      const title = "🏆 Mighty Spin Winner";
      const bodyText = `Winner announced for ${spin.city}: ${winnerCode ?? "Check app"}.`;

      // fcm v1 helper sends 1 request per token, so chunk just for safety/logging
      for (const part of chunk(tokens, 200)) {
        const res = await sendFcmToTokens(part, title, bodyText);
        sent += (res?.sent as number) || part.length;
      }
    }

    // 4) Return original success fields (plus extra push info)
    return json(200, {
      ok: true,
      winner_user_id: winnerUserId,
      winner_code: winnerCode,
      push: { ok: true, sent, city: spin.city },
    });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
