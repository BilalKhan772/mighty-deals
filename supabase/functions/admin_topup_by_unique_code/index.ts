import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Body = { unique_code: string; amount: number; type?: "topup" | "admin_mint" };

function json(status: number, data: Record<string, unknown>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req) => {
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
    const unique = (body.unique_code ?? "").trim();
    const amount = Number(body.amount ?? 0);
    const entryType = body.type ?? "topup";

    if (!unique.startsWith("#") || unique.length < 2) return json(400, { error: "INVALID_UNIQUE_CODE" });
    if (!Number.isFinite(amount) || amount <= 0) return json(400, { error: "INVALID_AMOUNT" });

    const { data, error } = await client.rpc("rpc_admin_topup_by_unique_code", {
      unique_code: unique,
      amount,
      entry_type: entryType,
    });

    if (error) {
      const msg = error.message || "RPC_FAILED";
      if (msg.includes("FORBIDDEN")) return json(403, { error: "FORBIDDEN" });
      if (msg.includes("USER_NOT_FOUND")) return json(404, { error: "USER_NOT_FOUND" });
      if (msg.includes("INVALID_TYPE")) return json(400, { error: "INVALID_TYPE" });
      return json(500, { error: "RPC_ERROR", details: msg });
    }

    const row = Array.isArray(data) ? data[0] : data;

    return json(200, {
      ok: true,
      user_id: row.target_user_id,
      balance_before: row.balance_before,
      balance_after: row.balance_after,
    });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
