import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Body = {
  spin_id: string;
  entry_type: "free" | "paid";
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
    const entryType = body.entry_type;

    if (!spinId) return json(400, { error: "SPIN_ID_REQUIRED" });
    if (entryType !== "free" && entryType !== "paid") return json(400, { error: "INVALID_ENTRY_TYPE" });

    if (entryType === "free") {
      const { data, error } = await client.rpc("rpc_spin_register_free", { spin_id: spinId });
      if (error) {
        const m = error.message ?? "RPC_ERROR";
        if (m.includes("FREE_NOT_AVAILABLE")) return json(400, { error: "FREE_NOT_AVAILABLE" });
        if (m.includes("FREE_SLOTS_FULL")) return json(400, { error: "FREE_SLOTS_FULL" });
        if (m.includes("ALREADY_JOINED_FREE")) return json(400, { error: "ALREADY_JOINED_FREE" });
        if (m.includes("REG_CLOSED")) return json(400, { error: "REG_CLOSED" });
        if (m.includes("REG_NOT_STARTED")) return json(400, { error: "REG_NOT_STARTED" });
        if (m.includes("SPIN_NOT_OPEN")) return json(400, { error: "SPIN_NOT_OPEN" });
        return json(500, { error: "RPC_ERROR", details: m });
      }
      const row = Array.isArray(data) ? data[0] : data;
      return json(200, { ok: true, entry_type: "free", entry_id: row.entry_id });
    }

    // paid
    const { data, error } = await client.rpc("rpc_spin_register_paid", { spin_id: spinId });
    if (error) {
      const m = error.message ?? "RPC_ERROR";
      if (m.includes("INSUFFICIENT_BALANCE")) return json(400, { error: "INSUFFICIENT_BALANCE" });
      if (m.includes("REG_CLOSED")) return json(400, { error: "REG_CLOSED" });
      if (m.includes("REG_NOT_STARTED")) return json(400, { error: "REG_NOT_STARTED" });
      if (m.includes("SPIN_NOT_OPEN")) return json(400, { error: "SPIN_NOT_OPEN" });
      return json(500, { error: "RPC_ERROR", details: m });
    }

    const row = Array.isArray(data) ? data[0] : data;
    return json(200, {
      ok: true,
      entry_type: "paid",
      entry_id: row.entry_id,
      balance_before: row.balance_before,
      balance_after: row.balance_after,
    });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
