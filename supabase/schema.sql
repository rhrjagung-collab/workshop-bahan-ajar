-- ============================================================
-- Skema Supabase v2 — Modul Persiapan Daring
-- Workshop Inovasi Bahan Ajar Digital Jaminan Sosial
--
-- Cara pakai: Supabase Dashboard > SQL Editor > New query >
-- tempel SELURUH file ini > Run (aman dijalankan ulang).
--
-- Model auth (v3):
--  - Login via Supabase Auth: Google (Gmail) ATAU nama pengguna/email + kata sandi
--    yang dibuat administrasi (Dashboard > Authentication > Add user,
--    centang Auto Confirm; matikan "Allow new users to sign up" agar
--    hanya admin yang bisa membuat akun).
--  - Nama pengguna (kolom username, diatur admin) diterjemahkan ke email
--    lewat lookup_login_email sebelum signInWithPassword.
--  - Saat pertama kali login, RPC bind_and_get_me menghubungkan akun
--    auth dengan baris roster (berdasarkan auth_user_id atau email).
--    Bila email belum terdaftar di roster (mis. login Gmail), baris
--    peserta baru dibuat otomatis (peran 'peserta').
--  - Peran: peserta | fasilitator | narasumber | admin.
--    Dashboard dibuka untuk admin/fasilitator/narasumber; kontrol
--    buka-kunci progres hanya untuk admin.
-- ============================================================

-- 1) Tabel roster peserta -----------------------------------------------
create table if not exists public.participants (
  id           uuid primary key default gen_random_uuid(),
  nama         text not null,
  email        text not null unique,
  username     text unique,                        -- login alternatif selain email
  kelompok     text not null default '-',
  kode_access  text,                              -- warisan v1, tidak dipakai lagi
  peran        text not null default 'peserta',   -- peserta | fasilitator | narasumber | admin
  auth_user_id uuid unique,                       -- auth.users.id, diisi saat login pertama
  created_at   timestamptz not null default now()
);

-- v3: kolom username (aman untuk instalasi lama)
alter table public.participants add column if not exists username text;

-- 2) Progres per item (blok interaktif, LK, refleksi) --------------------
create table if not exists public.item_progress (
  participant_id uuid not null references public.participants(id) on delete cascade,
  module_code    text not null,
  item_key       text not null,
  state          jsonb not null default '{}'::jsonb,
  updated_at     timestamptz not null default now(),
  primary key (participant_id, module_code, item_key)
);

-- 3) Progres per modul ----------------------------------------------------
create table if not exists public.module_progress (
  participant_id uuid not null references public.participants(id) on delete cascade,
  module_code    text not null,
  percent        int  not null default 0,
  status         text not null default 'belum', -- belum | mulai | selesai
  updated_at     timestamptz not null default now(),
  primary key (participant_id, module_code)
);

-- 4) Respons kuis (pre/modul/akhir) untuk analitik fasilitator ------------
create table if not exists public.quiz_responses (
  id             uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.participants(id) on delete cascade,
  quiz_kind      text not null,                 -- pre | modul | akhir
  module_code    text not null,
  question_id    text not null,
  answer         text,
  is_correct     boolean,
  attempt        int  not null default 1,
  created_at     timestamptz not null default now()
);
create index if not exists idx_quiz_participant on public.quiz_responses (participant_id, quiz_kind);
create index if not exists idx_quiz_question   on public.quiz_responses (module_code, question_id);

-- 5) Helper: peserta milik sesi saat ini ---------------------------------
-- Murni pembacaan (pengikatan email→akun hanya terjadi di bind_and_get_me):
-- cocokkan auth_user_id; bila belum terikat, cocokkan email tanpa mengubah.
create or replace function public.current_participant_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select id from public.participants
   where auth_user_id = auth.uid()
      or (auth_user_id is null
          and lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')))
   limit 1;
$$;

create or replace function public.is_faculty()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.participants
    where auth_user_id = auth.uid()
      and peran in ('fasilitator','narasumber','admin')
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.participants
    where auth_user_id = auth.uid() and peran = 'admin'
  );
$$;

-- 6) RPC: ikat + ambil profil sesi (dipanggil frontend setelah login) -----
-- Bila belum terikat: cari roster berdasarkan email; bila tidak ada, buat
-- baris peserta baru (login Gmail di luar roster).
create or replace function public.bind_and_get_me()
returns setof public.participants
language plpgsql security definer set search_path = public
as $$
declare
  v_email text;
  v_id uuid;
  v_nama text;
begin
  if auth.uid() is null then return; end if;
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  select id into v_id from public.participants where auth_user_id = auth.uid();
  if v_id is null and v_email <> '' then
    select id into v_id from public.participants where lower(email) = v_email;
    if v_id is not null then
      update public.participants set auth_user_id = auth.uid() where id = v_id;
    end if;
  end if;

  if v_id is null then
    v_nama := initcap(split_part(v_email, '@', 1));
    insert into public.participants (nama, email, username, kelompok, peran, auth_user_id)
    values (
      v_nama, v_email,
      case when v_email like '%@peserta.lokal' then lower(split_part(v_email, '@', 1)) end,
      '-', 'peserta', auth.uid()
    )
    on conflict (email) do update set auth_user_id = excluded.auth_user_id
    returning id into v_id;
  end if;

  -- Sinkronkan nama pengguna untuk akun internal (@peserta.lokal) yang
  -- belum memilikinya, agar login nama pengguna selalu tersedia.
  update public.participants
     set username = lower(split_part(email, '@', 1))
   where id = v_id
     and username is null
     and email like '%@peserta.lokal';

  return query select * from public.participants where id = v_id;
end;
$$;

-- 7) RPC admin: kelola peran dan buka-kunci progres peserta ---------------

-- Ubah peran peserta (admin saja)
create or replace function public.admin_set_peran(p_email text, p_peran text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat mengubah peran.';
  end if;
  if p_peran not in ('peserta','fasilitator','narasumber','admin') then
    raise exception 'Peran tidak valid.';
  end if;
  update public.participants set peran = p_peran where lower(email) = lower(p_email);
end;
$$;

-- Set progres satu modul peserta (admin saja) — dipakai untuk membuka
-- (tandai 100/selesai) atau mengulang (0/belum) modul seorang peserta.
create or replace function public.admin_set_module_progress(
  p_participant_id uuid, p_module_code text, p_percent int, p_status text
)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat mengubah progres peserta.';
  end if;
  if p_status not in ('belum','mulai','selesai') then
    raise exception 'Status tidak valid.';
  end if;
  insert into public.module_progress (participant_id, module_code, percent, status, updated_at)
  values (p_participant_id, p_module_code, p_percent, p_status, now())
  on conflict (participant_id, module_code) do update
    set percent = excluded.percent, status = excluded.status, updated_at = now();
end;
$$;

-- Reset seluruh progres seorang peserta (admin saja)
create or replace function public.admin_reset_all_progress(p_participant_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat mereset progres peserta.';
  end if;
  delete from public.item_progress where participant_id = p_participant_id;
  delete from public.module_progress where participant_id = p_participant_id;
  delete from public.quiz_responses where participant_id = p_participant_id;
end;
$$;

-- Atur nama pengguna peserta (admin saja) — dipakai untuk login tanpa email
create or replace function public.admin_set_username(p_participant_id uuid, p_username text)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat mengatur nama pengguna.';
  end if;
  p_username := lower(trim(p_username));
  if p_username is null or length(p_username) < 3 then
    raise exception 'Nama pengguna minimal 3 karakter.';
  end if;
  if p_username ~ '[^a-z0-9._-]' then
    raise exception 'Nama pengguna hanya boleh huruf kecil, angka, titik, garis bawah, dan tanda hubung.';
  end if;
  update public.participants set username = p_username where id = p_participant_id;
end;
$$;

-- Terjemahkan nama pengguna menjadi email untuk login (publik, tanpa data sensitif)
create or replace function public.lookup_login_email(p_username text)
returns text
language sql stable security definer set search_path = public
as $$
  select lower(email) from public.participants
   where lower(username) = lower(trim(p_username))
     and email is not null
   limit 1;
$$;

-- Buat akun login lengkap untuk peserta baru (admin saja):
-- membuat baris auth.users + auth.identities (setara "Add user" di Dashboard)
-- sekaligus baris roster participants — semuanya dalam satu panggilan.
-- Email bersifat opsional: bila dikosongkan, dibuat email internal
-- sintetis <username>@peserta.lokal dan login tetap lewat nama pengguna.
create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_create_user(
  p_nama text, p_email text default null, p_password text default null,
  p_username text default null, p_kelompok text default '-'
)
returns table (ok boolean, message text)
language plpgsql security definer set search_path = public, auth, extensions
as $$
declare
  v_uid uuid;
begin
  if not public.is_admin() then
    return query select false, 'Hanya admin yang dapat menambah peserta.';
    return;
  end if;

  p_email := lower(trim(coalesce(p_email, '')));
  if p_email = '' then p_email := null; end if;
  if p_email is not null and p_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then
    return query select false, 'Format email tidak valid.';
    return;
  end if;
  if length(coalesce(p_password, '')) < 6 then
    return query select false, 'Kata sandi minimal 6 karakter.';
    return;
  end if;
  if length(coalesce(trim(p_nama), '')) < 2 then
    return query select false, 'Nama minimal 2 karakter.';
    return;
  end if;

  p_username := lower(trim(coalesce(p_username, '')));
  if p_username <> '' and length(p_username) >= 3 then
    if p_username ~ '[^a-z0-9._-]' then
      return query select false, 'Nama pengguna hanya boleh huruf kecil, angka, titik, garis bawah, tanda hubung.';
      return;
    end if;
    if exists (select 1 from public.participants where username = p_username) then
      return query select false, 'Nama pengguna "' || p_username || '" sudah dipakai.';
      return;
    end if;
  else
    p_username := null;
  end if;

  -- Email opsional: tanpa email, nama pengguna wajib dan email internal dibuat otomatis.
  if p_email is null then
    if p_username is null then
      return query select false, 'Isi email ATAU nama pengguna (tanpa keduanya akun tidak dapat dibuat).';
      return;
    end if;
    p_email := p_username || '@peserta.lokal';
  end if;

  if exists (select 1 from auth.users where lower(email) = p_email) then
    return query select false, 'Email "' || p_email || '" sudah terdaftar.';
    return;
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, confirmation_token, recovery_token,
    email_change, email_change_token_new
  ) values (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(), 'authenticated', 'authenticated',
    p_email, crypt(p_password, gen_salt('bf')), now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
    now(), now(), '', '', '', ''
  ) returning id into v_uid;

  -- provider_id untuk identitas email = email pengguna (bukan string 'email'),
  -- constraint unik (provider_id, provider) menuntut satu baris per email.
  insert into auth.identities (id, user_id, provider, provider_id, identity_data, last_sign_in_at, created_at, updated_at)
  values (
    gen_random_uuid(), v_uid, 'email', p_email,
    jsonb_build_object('sub', v_uid::text, 'email', p_email, 'email_verified', true),
    now(), now(), now()
  );

  insert into public.participants (nama, email, username, kelompok, peran)
  values (trim(p_nama), p_email, p_username, coalesce(nullif(trim(p_kelompok), ''), '-'), 'peserta')
  on conflict (email) do update set peran = 'peserta', username = excluded.username;

  return query select true, 'Peserta ' || coalesce(p_username, p_email) || ' berhasil dibuat — akun siap dipakai login (email internal: ' || p_email || ').';

exception
  when unique_violation then
    return query select false, 'Gagal: identitas/email sudah terdaftar pada sistem autentikasi.';
  when foreign_key_violation then
    return query select false, 'Gagal: referensi pengguna tidak valid.';
end;
$$;

-- Hapus peserta (admin saja): baris roster + seluruh progres terhapus
-- (rantai on-delete-cascade), termasuk akun login auth terkait bila ada.
create or replace function public.admin_delete_user(p_participant_id uuid)
returns void
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_auth uuid;
begin
  if not public.is_admin() then
    raise exception 'Hanya admin yang dapat menghapus peserta.';
  end if;
  if p_participant_id = public.current_participant_id() then
    raise exception 'Tidak dapat menghapus akun Anda sendiri.';
  end if;
  select auth_user_id into v_auth from public.participants where id = p_participant_id;
  delete from public.participants where id = p_participant_id;
  if v_auth is not null then
    delete from auth.users where id = v_auth;
  end if;
end;
$$;

grant execute on function public.bind_and_get_me() to authenticated;
grant execute on function public.admin_set_peran(text, text) to authenticated;
grant execute on function public.admin_set_module_progress(uuid, text, int, text) to authenticated;
grant execute on function public.admin_reset_all_progress(uuid) to authenticated;
grant execute on function public.admin_set_username(uuid, text) to authenticated;
grant execute on function public.admin_create_user(text, text, text, text, text) to authenticated;
grant execute on function public.admin_delete_user(uuid) to authenticated;
grant execute on function public.lookup_login_email(text) to anon, authenticated;

-- Perbaikan otomatis (idempoten): identitas email lama yang provider_id-nya
-- salah (mis. 'email' alih-alih alamat email) diselaraskan dengan auth.users.
-- Tanpa ini, akun yang dibuat sebelum perbaikan tidak dapat login.
update auth.identities i
set provider_id = lower(u.email),
    identity_data = jsonb_build_object('sub', u.id::text, 'email', lower(u.email), 'email_verified', true)
from auth.users u
where i.user_id = u.id
  and i.provider = 'email'
  and i.provider_id <> lower(u.email);

-- 8) Hapus RPC lama v1 (sesi anonim + kode akses) -------------------------
drop function if exists public.claim_participant(text, text);
drop function if exists public.get_me();

-- 9) Row Level Security ---------------------------------------------------
alter table public.participants    enable row level security;
alter table public.item_progress   enable row level security;
alter table public.module_progress enable row level security;
alter table public.quiz_responses  enable row level security;

-- participants: lihat baris sendiri; tim boleh melihat semua
drop policy if exists "baca diri sendiri" on public.participants;
create policy "baca diri sendiri" on public.participants
  for select using (auth_user_id = auth.uid() or (current_participant_id() = id and auth.uid() is not null));
drop policy if exists "fasilitator baca semua" on public.participants;
create policy "fasilitator baca semua" on public.participants
  for select using (public.is_faculty());

-- item_progress
drop policy if exists "tulis baca milik sendiri" on public.item_progress;
create policy "tulis baca milik sendiri" on public.item_progress
  for all using (participant_id = public.current_participant_id())
  with check (participant_id = public.current_participant_id());
drop policy if exists "fasilitator baca semua" on public.item_progress;
create policy "fasilitator baca semua" on public.item_progress
  for select using (public.is_faculty());

-- module_progress
drop policy if exists "tulis baca milik sendiri" on public.module_progress;
create policy "tulis baca milik sendiri" on public.module_progress
  for all using (participant_id = public.current_participant_id())
  with check (participant_id = public.current_participant_id());
drop policy if exists "fasilitator baca semua" on public.module_progress;
create policy "fasilitator baca semua" on public.module_progress
  for select using (public.is_faculty());

-- quiz_responses
drop policy if exists "tulis baca milik sendiri" on public.quiz_responses;
create policy "tulis baca milik sendiri" on public.quiz_responses
  for all using (participant_id = public.current_participant_id())
  with check (participant_id = public.current_participant_id());
drop policy if exists "fasilitator baca semua" on public.quiz_responses;
create policy "fasilitator baca semua" on public.quiz_responses
  for select using (public.is_faculty());

-- ============================================================
-- 10) Contoh isi roster — GANTI dengan data peserta asli!
--     Peserta dibuat di sini (atau Table Editor) dengan email yang
--     SAMA dengan akun Auth yang dibuat administrasi; pengikatan
--     terjadi otomatis saat login pertama.
-- ============================================================
insert into public.participants (nama, email, kelompok, peran) values
  ('Contoh Peserta Satu',   'peserta1@contoh.id', 'Kelompok 1', 'peserta'),
  ('Contoh Fasilitator',    'fasilitator@contoh.id', 'Tim', 'fasilitator'),
  ('Contoh Admin',          'admin@contoh.id', 'Tim', 'admin')
on conflict (email) do nothing;

-- Menjadikan seseorang admin (jalankan dengan email Anda sendiri):
-- update public.participants set peran = 'admin' where lower(email) = 'nama.anda@gmail.com';

-- Catatan operasional:
-- - Buat akun login di Dashboard > Authentication > Add user (email + sandi,
--   centang Auto Confirm) dengan email yang sama dengan roster di atas.
-- - Login Google: aktifkan di Authentication > Sign In / Providers > Google
--   (isi Client ID + Client Secret dari Google Cloud Console; ikuti panduan
--   README bagian deployment).
-- - Kontrol admin (ubah peran, buka kunci, reset progres) tersedia di
--   halaman Dashboard setelah login sebagai admin.
