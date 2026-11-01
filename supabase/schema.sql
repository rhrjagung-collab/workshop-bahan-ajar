-- ============================================================
-- Skema Supabase — Modul Persiapan Daring
-- Workshop Inovasi Bahan Ajar Digital Jaminan Sosial
--
-- Cara pakai: Supabase Dashboard > SQL Editor > New query >
-- tempel seluruh file ini > Run.
--
-- Model keamanan:
--  - Peserta login TANPA registrasi publik: masukkan email + kode akses
--    (RPC claim_participant, SECURITY DEFINER, hanya mengklaim baris roster).
--  - Sesi memakai Supabase Auth anonymous; identitas peserta disambungkan
--    lewat participants.auth_user_id.
--  - RLS: peserta hanya melihat/mengubah baris miliknya.
--    Fasilitator/narasumber/admin (peran di roster) dapat membaca semua
--    untuk kebutuhan dashboard.
-- ============================================================

-- 1) Tabel roster peserta -----------------------------------------------
create table if not exists public.participants (
  id           uuid primary key default gen_random_uuid(),
  nama         text not null,
  email        text not null unique,
  kelompok     text not null default '-',
  kode_access  text not null,
  peran        text not null default 'peserta', -- peserta | fasilitator | narasumber | admin
  auth_user_id uuid unique,                      -- diisi oleh claim_participant
  created_at   timestamptz not null default now()
);

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
create or replace function public.current_participant_id()
returns uuid
language sql stable security definer set search_path = public
as $$
  select id from public.participants where auth_user_id = auth.uid();
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

-- 6) RPC login: klaim baris roster dengan email + kode -------------------
-- Mengembalikan baris peserta bila cocok; kosong bila tidak.
create or replace function public.claim_participant(p_email text, p_kode text)
returns setof public.participants
language plpgsql security definer set search_path = public
as $$
begin
  update public.participants
     set auth_user_id = auth.uid()
   where lower(email) = lower(p_email)
     and kode_access = p_kode
     and (auth_user_id is null or auth_user_id = auth.uid());
  if not found then
    return;
  end if;
  return query
    select * from public.participants
     where auth_user_id = auth.uid();
end;
$$;

create or replace function public.get_me()
returns setof public.participants
language sql stable security definer set search_path = public
as $$
  select * from public.participants where auth_user_id = auth.uid();
$$;

grant execute on function public.claim_participant(text, text) to anon, authenticated;
grant execute on function public.get_me() to anon, authenticated;

-- 7) Row Level Security ---------------------------------------------------
alter table public.participants    enable row level security;
alter table public.item_progress   enable row level security;
alter table public.module_progress enable row level security;
alter table public.quiz_responses  enable row level security;

-- participants: lihat baris sendiri; tim fasilitator boleh melihat semua
create policy "baca diri sendiri" on public.participants
  for select using (auth_user_id = auth.uid());
create policy "fasilitator baca semua" on public.participants
  for select using (public.is_faculty());

-- item_progress
create policy "tulis baca milik sendiri" on public.item_progress
  for all using (participant_id = public.current_participant_id())
  with check (participant_id = public.current_participant_id());
create policy "fasilitator baca semua" on public.item_progress
  for select using (public.is_faculty());

-- module_progress
create policy "tulis baca milik sendiri" on public.module_progress
  for all using (participant_id = public.current_participant_id())
  with check (participant_id = public.current_participant_id());
create policy "fasilitator baca semua" on public.module_progress
  for select using (public.is_faculty());

-- quiz_responses
create policy "tulis baca milik sendiri" on public.quiz_responses
  for all using (participant_id = public.current_participant_id())
  with check (participant_id = public.current_participant_id());
create policy "fasilitator baca semua" on public.quiz_responses
  for select using (public.is_faculty());

-- ============================================================
-- 8) Contoh isi roster — GANTI dengan data peserta asli!
--    Peran: 'peserta' untuk peserta; gunakan 'fasilitator'/'narasumber'
--    untuk tim agar bisa membuka dashboard.
-- ============================================================
insert into public.participants (nama, email, kelompok, kode_access, peran) values
  ('Contoh Peserta Satu',   'peserta1@contoh.id', 'Kelompok 1', 'MJS-DEMO-01', 'peserta'),
  ('Contoh Peserta Dua',    'peserta2@contoh.id', 'Kelompok 1', 'MJS-DEMO-02', 'peserta'),
  ('Contoh Fasilitator',    'fasilitator@contoh.id', 'Tim', 'MJS-FASIL-01', 'fasilitator'),
  ('Contoh Narasumber',     'narasumber@contoh.id', 'Tim', 'MJS-NARA-01', 'narasumber')
on conflict (email) do nothing;

-- Catatan operasional:
-- - Kode akses sebaiknya unik per orang dan dikirim via kanal resmi (email/WA).
-- - Untuk menonaktifkan peserta: delete barisnya atau kosongkan auth_user_id.
-- - claim_participant hanya bisa dipanggil sekali per baris (kode sekali pakai
--   per akun peramban) — bila peserta ganti perangkat, hubungi admin untuk
--   mengosongkan auth_user_id pada baris tersebut.
