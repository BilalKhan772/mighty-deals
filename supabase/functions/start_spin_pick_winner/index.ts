import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Body = {
  spin_id: string;
  forced_unique_code?: string | null; // e.g. "#1022"
};

function json(status: number, data: Record<string, unknown>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  try {
    if (req.method !== "POST") return json(405, { error: "Method not allowed" });

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    if (!supabaseUrl || !anonKey) return json(500, { error: "Missing env vars" });

    const authHeader = req.headers.get("Authorization") ?? "";
    const client = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: authData, error: authErr } = await client.auth.getUser();
    if (authErr || !authData?.user) return json(401, { error: "Unauthorized" });

    const body = (await req.json()) as Body;
    const spinId = (body.spin_id ?? "").trim();
    const forced = body.forced_unique_code?.trim() || null;

    if (!spinId) return json(400, { error: "SPIN_ID_REQUIRED" });

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
    return json(200, { ok: true, winner_user_id: row.winner_user_id, winner_code: row.winner_code });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
