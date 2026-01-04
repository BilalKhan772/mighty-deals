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
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });

    const { data: authData } = await authClient.auth.getUser();
    const callerId = authData?.user?.id;
    if (!callerId) return json(401, { error: "Unauthorized" });

    const sb = createClient(supabaseUrl, serviceKey);

    // Admin check via profiles.role
    const { data: callerProfile } = await sb
      .from("profiles")
      .select("role")
      .eq("id", callerId)
      .maybeSingle();

    if (callerProfile?.role !== "admin") return json(403, { error: "FORBIDDEN" });

    const body = (await req.json()) as Body;
    const unique = (body.unique_code ?? "").trim();
    const amount = Number(body.amount ?? 0);
    const entryType = body.type ?? "topup";

    if (!unique.startsWith("#") || unique.length < 2) return json(400, { error: "INVALID_UNIQUE_CODE" });
    if (!Number.isFinite(amount) || amount <= 0) return json(400, { error: "INVALID_AMOUNT" });

    const { data: prof, error: pErr } = await sb
      .from("profiles")
      .select("id")
      .eq("unique_code", unique)
      .maybeSingle();

    if (pErr) return json(500, { error: "Profile lookup failed", details: pErr.message });
    if (!prof) return json(404, { error: "USER_NOT_FOUND" });

    const userId = prof.id;

    await sb.from("wallets").upsert({ user_id: userId }, { onConflict: "user_id" });

    const { data: wallet, error: wErr } = await sb
      .from("wallets")
      .select("balance")
      .eq("user_id", userId)
      .maybeSingle();

    if (wErr) return json(500, { error: "Wallet fetch failed", details: wErr.message });

    const before = Number(wallet?.balance ?? 0);
    const after = before + amount;

    const { error: lErr } = await sb.from("wallet_ledger").insert({
      user_id: userId,
      type: entryType,
      amount: amount,
      reference_type: "admin_topup",
      reference_id: null,
      created_by: callerId,
    });

    if (lErr) return json(500, { error: "Ledger insert failed", details: lErr.message });

    const { error: uErr } = await sb.from("wallets").update({ balance: after }).eq("user_id", userId);
    if (uErr) return json(500, { error: "Wallet update failed", details: uErr.message });

    return json(200, { ok: true, user_id: userId, balance_before: before, balance_after: after });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
