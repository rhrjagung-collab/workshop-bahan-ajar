-- ============================================================
-- DIAGNOSTIK AUTH — jalankan di Supabase SQL Editor, kirim hasilnya
-- Menampilkan kondisi setiap akun: sandi, identitas, ikatan roster.
-- ============================================================
select
  u.email                                                          as "email akun",
  (u.encrypted_password is not null and u.encrypted_password <> '') as "punya kata sandi",
  u.email_confirmed_at is not null                                 as "email terkonfirmasi",
  u.created_at::date                                               as "dibuat",
  i.provider                                                       as "provider identitas",
  i.provider_id                                                    as "provider_id identitas",
  (i.provider = 'email' and i.provider_id = lower(u.email))        as "identitas benar?",
  p.id is not null                                                 as "terikat roster?",
  p.peran                                                          as "peran",
  p.username                                                       as "username"
from auth.users u
left join auth.identities i on i.user_id = u.id
left join public.participants p on p.auth_user_id = u.id
order by u.created_at;

-- Ringkasan cepat: akun Google tidak punya kata sandi (normal);
-- akun email wajib "punya kata sandi" = true DAN "identitas benar?" = true.
