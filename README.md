# Modul Persiapan Daring — Workshop Inovasi Bahan Ajar Digital Jaminan Sosial

Aplikasi web modular (8 modul, C0–C7) untuk persiapan peserta sebelum Workshop Inovasi Bahan Ajar Digital Jaminan Sosial, **9–10 November 2026, Swiss-belhotel Bogor** — diselenggarakan Corporate University BPJS Kesehatan, kolaborasi akademik UPN Veteran Jakarta.

- **Frontend**: Vue 3 + Vite (SPA, hash routing), konten modul berupa file JSON
- **Backend**: Supabase — Auth (Google/Gmail **atau** email + kata sandi buatan admin), Postgres + RLS
- **Hosting**: Vercel (statis)
- **Peran**: `peserta` • `fasilitator`/`narasumber` (dashboard pemantauan) • `admin` (dashboard + buka kunci progres + atur peran + atur nama pengguna)
- **Login**: akun Google (Gmail) **atau** nama pengguna/email + kata sandi buatan admin; halaman Masuk tampil otomatis bagi pengunjung yang belum masuk

---

## 1. Menjalankan di komputer lokal

Prasyarat: Node.js 18+ dan npm.

```bash
cd modul-jaminan-sosial
npm install
npm run dev          # buka URL yang tampil (default http://localhost:5173)
```

Tanpa file `.env`, kredensial Supabase produksi dipakai sebagai nilai bawaan (URL proyek + kunci publishable memang data publik). Bila ingin mode demo murni lokal (tanpa jaringan), isi `.env.local` dengan nilai kosong:

```
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Demo lokal: login dengan email apa pun + sandi ≥ 4 karakter; email berawalan `admin`/`fasilitator` mendapat peran terkait.

```bash
npm run build        # hasil produksi di folder dist/
npm run preview      # pratinjau hasil build
```

## 2. Menyiapkan backend Supabase (±15 menit)

Proyek: **oltafrxhkzojbdowcydc** (URL: `https://oltafrxhkzojbdowcydc.supabase.co`).

1. Buka [supabase.com/dashboard](https://supabase.com/dashboard) → pilih proyek.
2. **SQL Editor → New query** → tempel seluruh `supabase/schema.sql` → **Run**.
   Ini membuat tabel, fungsi pengikatan login (`bind_and_get_me`), RPC admin
   (`admin_set_peran`, `admin_set_module_progress`, `admin_reset_all_progress`),
   dan kebijakan RLS. Aman dijalankan ulang.
3. **Muat roster peserta** (nama, email, kelompok) — SQL bagian bawah schema,
   Table Editor, atau impor `supabase/roster.template.csv` (kolom `nama,email,kelompok,peran`).
4. **Buat akun login peserta**: Dashboard → **Authentication → Users → Add user** →
   isi email + kata sandi → centang **Auto Confirm User**. Email harus sama dengan roster.
   Lalu **matikan pendaftaran mandiri**: Authentication → Sign In / Providers → Email →
   nonaktifkan *Allow new users to sign up* (akun hanya dibuat admin).
   **Nama pengguna (opsional)**: setelah peserta login pertama kali (barisnya dibuat otomatis),
   admin mengisi kolom *Nama pengguna* di Dashboard → Kontrol admin. Peserta pun bisa
   login dengan nama pengguna itu sebagai ganti email (huruf kecil/angka/titik/garis bawah).
5. **Jadikan diri Anda admin** (sekali saja, di SQL Editor):
   ```sql
   update public.participants set peran = 'admin' where lower(email) = 'email.and@gmail.com';
   ```
   (Baris peserta untuk email tersebut dibuat otomatis saat Anda pertama kali login.)
6. **Aktifkan login Google (opsional, untuk jalur Gmail)**:
   - Google Cloud Console → buat *OAuth client ID* (tipe *Web application*);
     *Authorized redirect URI*: `https://oltafrxhkzojbdowcydc.supabase.co/auth/v1/callback`.
   - Supabase → Authentication → Sign In / Providers → **Google** → aktifkan,
     tempel Client ID + Client Secret → Save.
   - Catatan: kunci *secret* Supabase tidak diperlukan aplikasi ini — semua operasi
     admin berjalan lewat RPC SECURITY DEFINER + RLS. Jangan pernah menaruh
     service/secret key di kode klien.
7. **Redirect URL**: Authentication → URL Configuration → tambahkan
   `http://localhost:5173/**` dan nanti `https://<domain-vercel>/**`.

## 3. Deploy ke Vercel (±5 menit)

1. Push repo ke GitHub (lihat §5), lalu di [vercel.com](https://vercel.com) → **Add New → Project** → pilih `workshop-bahan-ajar`.
2. Vercel mendeteksi Vite otomatis (build `npm run build`, output `dist/`). Hash routing → tanpa rewrite khusus.
3. **Environment Variables** (Production *dan* Preview):

   | Nama | Nilai |
   |---|---|
   | `VITE_SUPABASE_URL` | `https://oltafrxhkzojbdowcydc.supabase.co` |
   | `VITE_SUPABASE_ANON_KEY` | kunci publishable Supabase |

   (Bila dikosongkan, nilai bawaan di `src/lib/config.js` yang sama dipakai.)
4. **Deploy**. Setelah dapat URL (mis. `https://workshop-bahan-ajar.vercel.app`), tambahkan
   `https://<url-vercel>/**` ke Redirect URL Supabase (langkah 2.7).
5. Setiap `git push` menghasilkan deploy baru; PR mendapat *preview URL*.

## 4. Operasional sebelum & selama workshop

| Waktu | Kegiatan |
|---|---|
| 4–5 Nov | Admin membuat akun login 25 peserta (Authentication → Add user) + mengirim email/sandi; jadwal: C0–C1 (5 Nov), C2–C3 (6 Nov), C4–C5 (7 Nov), C6–C7 (8 Nov), tenggat 21.00 WIB |
| 7–8 Nov | Fasilitator membuka **Dashboard** (`/#/dashboard`) — mengejar peserta yang tertinggal; membaca LK & brief per kelompok |
| Kapan pun | **Admin** membuka kunci modul peserta yang terkendala (Dashboard → Kontrol admin → *Tandai selesai*), mengulang progres, atau mengubah peran |
| Hari 1 | Tidak perlu pre-test ulang (sudah di C0); gunakan hasil LK1–LK3 sebagai bahan diskusi |
| Hari 2 pembuka | Retrieval quiz — pilih soal dari **"Soal tersulit"** di dashboard |
| Pasca | Tombol **Ekspor CSV** di dashboard untuk lampiran laporan |

Catatan teknis:

- **Login Google**: bila provider Google belum diaktifkan di Supabase, tombol Gmail
  menampilkan pesan untuk memakai email & kata sandi.
- **Peserta lupa sandi**: admin mereset di Authentication → Users → peserta → *Send password recovery* / ubah sandi.
- **Peran baru**: admin mengubah peran langsung dari Dashboard (Kontrol admin), tanpa SQL.
- **Backup**: Table Editor → Export CSV untuk tabel utama sesekali.

## 5. Git

```bash
git init
git add -A
git commit -m "feat: modul persiapan daring"
git remote add origin https://github.com/rhrjagung-collab/workshop-bahan-ajar.git
git push -u origin main
```

Sudah disiapkan `.gitignore` (node_modules, dist, .env).

## 6. Struktur proyek

```
modul-jaminan-sosial/
├─ index.html                # shell SPA (hash routing)
├─ src/
│  ├─ lib/                   # config, backend (Supabase|demo), store, course loader, router
│  ├─ content/               # KONTEN MODUL — edit di sini (c0…c7.json + course.json)
│  ├─ components/
│  │  ├─ blocks/             # 13 tipe blok interaktif (mcq, dragwords, matching, sort,
│  │  │                      #   compare, beforeafter, hotspot, form, reflect, quiz, dst.)
│  │  └─ SiteHeader/Footer, ProgressBar
│  ├─ pages/                 # Landing, Login (Google + email/sandi), ModulePage,
│  │                         #   MyPage (+sertifikat), Dashboard (+kontrol admin)
│  └─ styles/                # tokens.css (warna brand BPJS×UPNVJ), blocks.css
├─ public/
│  ├─ brand/                 # logo BPJS Kesehatan & UPNVJ
│  ├─ figures/               # figur riset + diagram orisinal (manifest.json: lisensi)
│  └─ bacaan/                # PDF bacaan wajib (CC BY) untuk peserta
├─ supabase/
│  ├─ schema.sql             # tabel + RLS + RPC auth/admin — jalankan di SQL Editor
│  └─ roster.template.csv    # format daftar peserta (nama,email,kelompok,peran)
└─ package.json
```

### Mengedit konten modul

Buka `src/content/cX-*.json` — setiap modul adalah daftar blok. Tipe blok:
`text`, `section`, `callout`, `figure` (opsional `link` ke sumber), `mcq`, `dragwords`,
`matching`, `sort`, `beforeafter`, `compare`, `hotspot`, `form`, `reflect`, `quiz`.
Blok interaktif wajib punya `item_key` unik. Setelah mengedit: `npm run dev` untuk mengecek,
lalu commit + push (deploy otomatis).

## 7. Desain & aksesibilitas

- Warna diekstrak dari logo resmi: BPJS Kesehatan (indigo `#2B3078`, hijau `#009F3C`),
  UPNVJ (kuning `#FFD200`; merah `#C8102E`).
- Kontras WCAG AA; navigasi keyboard; `prefers-reduced-motion`; figur punya `alt`;
  warna bukan satu-satunya pemberi makna; figur eksternal dapat diklik ke sumbernya.
- Sitasi dan lisensi tercantum pada tiap figur; PDF bacaan berlisensi terbuka.

## 8. Rujukan bukti (dipakai dalam modul)

Freeman et al. (2014) PNAS; Mayer (2024) EPR; Trumble et al. (2024) AHSE; Morris et al. (2021) Review of Education; Alam et al. (2025) Smart Learning Environments; Jurado-Castro et al. (2023) PeerJ CS; Güngör et al. (2026) Current Psychology; Jaleniauskiene & Kasperiuniene (2023); Zhang & Ma (2023) Frontiers in Psychology; Trullàs et al. (2022) BMC Med Educ; Wijnia et al. (2024) EPR; Traboco et al. (2022) JKMS; Kepmenaker 333/2020 (SKKNI). Daftar lengkap: `Daftar_Pustaka_dan_Link_Bacaan.xlsx` pada paket ToT.
