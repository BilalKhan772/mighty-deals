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
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    if (!supabaseUrl || !serviceKey || !anonKey) {
      return json(500, { error: "Missing Supabase env vars" });
    }

    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
    });

    const { data: authData, error: authErr } = await authClient.auth.getUser();
    if (authErr || !authData?.user) return json(401, { error: "Unauthorized" });

    const userId = authData.user.id;
    const body = (await req.json()) as Body;

    const dealId = body.deal_id?.trim() || null;
    const menuItemId = body.menu_item_id?.trim() || null;

    if ((dealId && menuItemId) || (!dealId && !menuItemId)) {
      return json(400, { error: "Provide exactly one of deal_id or menu_item_id" });
    }

    const sb = createClient(supabaseUrl, serviceKey);

    // profile snapshot
    const { data: profile, error: pErr } = await sb
      .from("profiles")
      .select("phone, whatsapp, address, city, is_profile_complete")
      .eq("id", userId)
      .maybeSingle();

    if (pErr) return json(500, { error: "Profile fetch failed", details: pErr.message });
    if (!profile?.is_profile_complete) return json(400, { error: "PROFILE_INCOMPLETE" });

    const phone = profile.phone ?? null;
    const whatsapp = profile.whatsapp ?? null;
    const address = profile.address ?? null;
    const city = profile.city ?? null;

    // resolve item
    let restaurantId: string;
    let coinsPrice: number;
    let ledgerType: string;

    if (dealId) {
      const { data: deal, error: dErr } = await sb
        .from("deals")
        .select("id, restaurant_id, price_mighty, is_active")
        .eq("id", dealId)
        .maybeSingle();

      if (dErr) return json(500, { error: "Deal fetch failed", details: dErr.message });
      if (!deal || deal.is_active !== true) return json(404, { error: "DEAL_NOT_FOUND" });

      restaurantId = deal.restaurant_id;
      coinsPrice = Number(deal.price_mighty ?? 0);
      ledgerType = "purchase_deal";
    } else {
      const { data: mi, error: mErr } = await sb
        .from("menu_items")
        .select("id, restaurant_id, price_mighty, is_active")
        .eq("id", menuItemId)
        .maybeSingle();

      if (mErr) return json(500, { error: "Menu item fetch failed", details: mErr.message });
      if (!mi || mi.is_active !== true) return json(404, { error: "MENU_ITEM_NOT_FOUND" });

      restaurantId = mi.restaurant_id;
      coinsPrice = Number(mi.price_mighty ?? 0);
      ledgerType = "purchase_menu";
    }

    if (!Number.isFinite(coinsPrice) || coinsPrice <= 0) {
      return json(400, { error: "INVALID_MIGHTY_PRICE" });
    }

    // restaurant checks
    const { data: rest, error: rErr } = await sb
      .from("restaurants")
      .select("id, is_deleted, is_restricted")
      .eq("id", restaurantId)
      .maybeSingle();

    if (rErr) return json(500, { error: "Restaurant fetch failed", details: rErr.message });
    if (!rest || rest.is_deleted) return json(404, { error: "RESTAURANT_NOT_FOUND" });
    if (rest.is_restricted) return json(403, { error: "RESTAURANT_RESTRICTED" });

    // ensure wallet row exists
    await sb.from("wallets").upsert({ user_id: userId }, { onConflict: "user_id" });

    // get balance
    const { data: wallet, error: wErr } = await sb
      .from("wallets")
      .select("balance")
      .eq("user_id", userId)
      .maybeSingle();

    if (wErr) return json(500, { error: "Wallet fetch failed", details: wErr.message });

    const balance = Number(wallet?.balance ?? 0);
    if (balance < coinsPrice) return json(400, { error: "INSUFFICIENT_BALANCE" });

    // create order
    const { data: orderRow, error: oErr } = await sb
      .from("orders")
      .insert({
        user_id: userId,
        restaurant_id: restaurantId,
        deal_id: dealId,
        menu_item_id: menuItemId,
        coins_paid: coinsPrice,
        phone,
        whatsapp,
        address,
        city,
        status: "pending",
      })
      .select("id")
      .single();

    if (oErr) return json(500, { error: "Order create failed", details: oErr.message });

    // ledger
    const { error: lErr } = await sb.from("wallet_ledger").insert({
      user_id: userId,
      type: ledgerType,
      amount: -coinsPrice,
      reference_type: "order",
      reference_id: orderRow.id,
      created_by: userId,
    });

    if (lErr) return json(500, { error: "Ledger insert failed", details: lErr.message });

    // update wallet
    const newBalance = balance - coinsPrice;
    const { error: uErr } = await sb.from("wallets").update({ balance: newBalance }).eq("user_id", userId);
    if (uErr) return json(500, { error: "Wallet update failed", details: uErr.message });

    return json(200, {
      ok: true,
      order_id: orderRow.id,
      coins_paid: coinsPrice,
      balance_before: balance,
      balance_after: newBalance,
    });
  } catch (e) {
    return json(500, { error: "SERVER_ERROR", details: String(e) });
  }
});
