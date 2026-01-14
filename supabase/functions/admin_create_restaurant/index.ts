import { createClient } from "@supabase/supabase-js";

type Payload = {
  email: string;
  password: string;
  name: string;
  city: string;
  address?: string;
  phone?: string;
  whatsapp?: string;
};

function json(status: number, data: unknown) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function getBearer(req: Request) {
  const h = req.headers.get("authorization") || req.headers.get("Authorization");
  if (!h) return null;
  const m = h.match(/^Bearer\s+(.+)$/i);
  return m ? m[1] : null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "Method not allowed" });

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
  const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
  const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const token = getBearer(req);
  if (!token) return json(401, { error: "Missing bearer token" });

  // Client using user's JWT (to validate admin)
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) return json(401, { error: "Invalid user token" });

  // Check admin role from profiles
  const { data: profile, error: profErr } = await userClient
    .from("profiles")
    .select("role,is_deleted")
    .eq("id", userData.user.id)
    .maybeSingle();

  if (profErr) return json(403, { error: "Admin check failed", detail: profErr.message });
  if (!profile || profile.is_deleted || profile.role !== "admin") {
    return json(403, { error: "Only admin can perform this action" });
  }

  let body: Payload;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "Invalid JSON body" });
  }

  const email = (body.email || "").trim().toLowerCase();
  const password = body.password || "";
  const name = (body.name || "").trim();
  const city = (body.city || "").trim();
  const address = body.address?.trim() || null;
  const phone = body.phone?.trim() || null;
  const whatsapp = body.whatsapp?.trim() || null;

  if (!email || !password || !name || !city) {
    return json(400, { error: "email, password, name, city are required" });
  }

  // Admin client with service role
  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // 1) Create auth user
  const { data: created, error: createErr } = await adminClient.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });

  if (createErr || !created?.user) {
    return json(400, { error: "Failed to create auth user", detail: createErr?.message });
  }

  const newUserId = created.user.id;

  // 2) Insert profile row (unique_code will be auto set by your trigger)
  const { error: pInsErr } = await adminClient.from("profiles").insert({
    id: newUserId,
    role: "restaurant",
  });

  if (pInsErr) {
    // rollback user
    await adminClient.auth.admin.deleteUser(newUserId);
    return json(400, { error: "Failed to create profile", detail: pInsErr.message });
  }

  // 3) Insert restaurant row
  const { data: rest, error: rInsErr } = await adminClient
    .from("restaurants")
    .insert({
      owner_user_id: newUserId,
      name,
      city,
      address,
      phone,
      whatsapp,
      is_restricted: false,
      is_deleted: false,
    })
    .select("*")
    .single();

  if (rInsErr) {
    // rollback both
    await adminClient.from("profiles").delete().eq("id", newUserId);
    await adminClient.auth.admin.deleteUser(newUserId);
    return json(400, { error: "Failed to create restaurant", detail: rInsErr.message });
  }

  return json(200, {
    ok: true,
    restaurant: rest,
    auth_user_id: newUserId,
  });
});
