-- 010_storage_objects_restaurants_rls.sql
-- Storage policies for restaurants bucket

alter table storage.objects enable row level security;

-- Public can view restaurant images (bucket is public)
drop policy if exists "restaurants_bucket_public_read" on storage.objects;
create policy "restaurants_bucket_public_read"
on storage.objects
for select
using (bucket_id = 'restaurants');

-- Admin can upload/update/delete anything in restaurants bucket
drop policy if exists "restaurants_bucket_admin_all" on storage.objects;
create policy "restaurants_bucket_admin_all"
on storage.objects
for all
using (bucket_id = 'restaurants' and public.is_admin())
with check (bucket_id = 'restaurants' and public.is_admin());

-- Restaurant owner can upload/update/delete only their own folder:
-- path: <restaurant_id>/profile.jpg
drop policy if exists "restaurants_bucket_owner_write_own" on storage.objects;
create policy "restaurants_bucket_owner_write_own"
on storage.objects
for all
using (
  bucket_id = 'restaurants'
  and (
    public.is_admin()
    or (
      auth.role() = 'authenticated'
      and split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and exists (
        select 1
        from public.restaurants r
        where r.id = split_part(name, '/', 1)::uuid
          and r.owner_user_id = auth.uid()
          and r.is_deleted = false
      )
    )
  )
)
with check (
  bucket_id = 'restaurants'
  and (
    public.is_admin()
    or (
      auth.role() = 'authenticated'
      and split_part(name, '/', 1) ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      and exists (
        select 1
        from public.restaurants r
        where r.id = split_part(name, '/', 1)::uuid
          and r.owner_user_id = auth.uid()
          and r.is_deleted = false
      )
    )
  )
);
