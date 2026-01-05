import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type Body = { deal_id?: string; menu_item_id?: string };

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
    const dealId = body.deal_id?.trim() || null;
    const menuItemId = body.menu_item_id?.trim() || null;

    if ((dealId && menuItemId) || (!dealId && !menuItemId)) {
      return json(400, { error: "Provide exactly one of deal_id or menu_item_id" });
    }

    const { data, error } = await client.rpc("rpc_create_order_and_deduct_coins", {
      deal_id: dealId,
      menu_item_id: menuItemId,
    });

    if (error) {
      const msg = error.message || "RPC_FAILED";
      if (msg.includes("PROFILE_INCOMPLETE")) return json(400, { error: "PROFILE_INCOMPLETE" });
      if (msg.includes("INSUFFICIENT_BALANCE")) return json(400, { error: "INSUFFICIENT_BALANCE" });
      if (msg.includes("DEAL_NOT_FOUND")) return json(404, { error: "DEAL_NOT_FOUND" });
      if (msg.includes("MENU_ITEM_NOT_FOUND")) return json(404, { error: "MENU_ITEM_NOT_FOUND" });
      if (msg.includes("RESTAURANT_NOT_ALLOWED")) return json(403, { error: "RESTAURANT_NOT_ALLOWED" });
      if (msg.includes("INVALID_MIGHTY_PRICE")) return json(400, { error: "INVALID_MIGHTY_PRICE" });

      return json(500, { error: "RPC_ERROR", details: msg });
    }

    // rpc returns an array of rows
    const row = Array.isArray(data) ? data[0] : data;

    return json(200, {
      ok: true,
      order_id: row.order_id,
      coins_paid: row.coins_paid,
      balance_before: row.balance_before,
      balance_after: row.balance_after,
    });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
