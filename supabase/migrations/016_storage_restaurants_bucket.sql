-- 016_storage_restaurants_bucket.sql
-- Create bucket for restaurant photos

insert into storage.buckets (id, name, public)
values ('restaurants', 'restaurants', true)
on conflict (id) do nothing;
