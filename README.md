# Modul Persiapan Daring — Workshop Inovasi Bahan Ajar Digital Jaminan Sosial

Aplikasi web modular (8 modul, C0–C7) untuk persiapan peserta sebelum Workshop Inovasi Bahan Ajar Digital Jaminan Sosial, **9–10 November 2026, Swiss-belhotel Bogor** — diselenggarakan Corporate University BPJS Kesehatan, kolaborasi akademik UPN Veteran Jakarta.

- **Frontend**: Vue 3 + Vite, konten modul berupa file JSON (mudah direvisi narasumber)
- **Backend**: Supabase (Postgres + Auth anonim + RLS) untuk progres, kuis, dan lembar kerja
- **Hosting**: statis — siap di-deploy ke Vercel (atau hosting statis mana pun)
- **Mode demo**: tanpa konfigurasi apa pun, aplikasi berjalan lokal dengan penyimpanan peramban

---

## 1. Menjalankan di komputer lokal

Prasyarat: Node.js 18+ (mis. v20/v22/v25) dan npm.

```bash
cd modul-jaminan-sosial
npm install
npm run dev          # buka URL yang tampil (default http://localhost:5173)
```

Tanpa file `.env`, aplikasi berjalan **mode demo**: login dengan email apa pun + kode ≥ 4 karakter
(awali email dengan `fasilitator@` mis. `fasilitator@demo.id` untuk melihat dashboard).
Progres tersimpan di localStorage peramban — cocok untuk uji tampilan dan materi, bukan untuk produksi.

```bash
npm run build        # hasil produksi di folder dist/
npm run preview      # pratinjau hasil build
```

## 2. Menyiapkan backend Supabase (±15 menit)

1. Buat akun gratis di [supabase.com](https://supabase.com) → **New project** (region terdekat, mis. Singapore). Simpan **database password**.
2. Buka **SQL Editor** → *New query* → tempel seluruh isi `supabase/schema.sql` → **Run**.
   Ini membuat tabel `participants`, `item_progress`, `module_progress`, `quiz_responses`,
   fungsi login `claim_participant`, helper RLS, kebijakan RLS, dan 4 baris roster contoh.
3. **Muat daftar peserta asli** (roster):
   - Opsi A — SQL: ganti blok `INSERT` terakhir di schema dengan data asli, jalankan ulang bagian itu saja.
   - Opsi B — Table Editor: buka tabel `participants`, tambahkan baris satu per satu.
   - Opsi C — Spreadsheet: siapkan CSV mengikuti `supabase/roster.template.csv`
     (kolom `nama,email,kelompok,kode_access,peran`) lalu impor via **Table Editor → Import data**.
   - Aturan kolom `peran`: `peserta` untuk peserta; `fasilitator` / `narasumber` / `admin` untuk tim
     (mereka mendapat akses dashboard). Kode akses buat unik per orang (mis. `MJS-XXXX-01`).
4. Ambil kredensial: **Project Settings → API** → salin **Project URL** dan **anon public key**.

### Mengaktifkan Supabase pada aplikasi

Buat file `.env.local` di akar folder proyek:

```
VITE_SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOi...   # anon public key (BUKAN service_role!)
```

Jalankan ulang `npm run dev`. Banner "mode demo" di footer akan hilang — login kini memakai roster Supabase.

> **Jangan pernah** memasukkan `service_role key` ke file `.env*` aplikasi — kunci itu hanya untuk server.

## 3. Deploy ke Vercel (±5 menit)

1. Push repo ini ke GitHub (lihat §5), lalu di [vercel.com](https://vercel.com) → **Add New → Project** → pilih repo.
2. Vercel mendeteksi Vite otomatis (build `npm run build`, output `dist/`). Tidak perlu rewrite khusus — aplikasi memakai hash routing (`/#/...`).
3. **Environment Variables** (Project → Settings → Environment Variables) — isi untuk *Production* *dan* *Preview*:

   | Nama | Nilai |
   |---|---|
   | `VITE_SUPABASE_URL` | URL proyek Supabase |
   | `VITE_SUPABASE_ANON_KEY` | anon public key Supabase |

4. **Deploy**. Bagikan URL hasilnya (mis. `https://modul-jaminan-sosial.vercel.app`) bersama email/kode akses.
   Domain kustom (opsional): Project → Settings → Domains.
5. Setiap `git push` menghasilkan deploy baru; PR menghasilkan *preview URL* — aman untuk revisi konten.

Alternatif tanpa Vercel: unggah isi `dist/` ke hosting statis apa pun (GitHub Pages, Netlify) —
jalankan `npm run build` lalu publikasikan foldernya.

## 4. Operasional sebelum & selama workshop

| Waktu | Kegiatan |
|---|---|
| 4–5 Nov | Admin mengirim URL + email/kode akses ke 25 peserta; jadwal: C0–C1 (5 Nov), C2–C3 (6 Nov), C4–C5 (7 Nov), C6–C7 (8 Nov), tenggat 21.00 WIB |
| 7–8 Nov | Fasilitator membuka **Dashboard** (`/#/dashboard`) — mengejar peserta yang belum mulai; membaca LK & brief per kelompok |
| Hari 1 | Tidak perlu pre-test ulang (sudah di C0); gunakan hasil LK1–LK3 sebagai bahan diskusi |
| Hari 2 pembuka | Retrieval quiz — pilih soal dari **"Soal tersulit"** di dashboard |
| Pasca | Tombol **Ekspor CSV** di dashboard untuk lampiran laporan |

Catatan teknis operasional:

- **Peserta ganti perangkat**: `claim_participant` mengikat satu akun anonim per baris roster.
  Bila peserta login di perangkat kedua gagal, kosongkan `auth_user_id` pada barisnya di Table Editor, lalu peserta login ulang dengan kode yang sama.
- **Kode akses bocor**: ganti `kode_access` peserta terkait.
- **Backup**: Table Editor → Export CSV untuk `participants`, `item_progress`, `module_progress`, `quiz_responses` (cukup sesekali; Supabase juga membuat backup harian otomatis pada tier berbayar).

## 5. Git

```bash
git init
git add -A
git commit -m "feat: modul persiapan daring C0-C7 + backend Supabase + panduan deploy"
git remote add origin <URL-REPO-BARU-ANDA>
git push -u origin main
```

Sudah disiapkan `.gitignore` (node_modules, dist, .env).

## 6. Struktur proyek

```
modul-jaminan-sosial/
├─ index.html                # shell SPA (hash routing)
├─ src/
│  ├─ lib/                   # config, backend (Supabase|demo), store, course loader, router
│  ├─ content/               # KONTEN MODUL — edit di sini
│  │  ├─ course.json         #   metadata course (judul, LO, credits, urutan modul)
│  │  └─ c0…c7 .json         #   satu file per modul: daftar "blok"
│  ├─ components/
│  │  ├─ blocks/             # 12 tipe blok interaktif (mcq, dragwords, matching, sort,
│  │  │                      #   beforeafter, hotspot, form, reflect, quiz, text, callout, figure)
│  │  └─ SiteHeader/Footer, ProgressBar
│  ├─ pages/                 # Landing, Login, ModulePage, MyPage (+sertifikat), Dashboard
│  └─ styles/                # tokens.css (warna brand BPJS×UPNVJ), blocks.css
├─ public/
│  ├─ brand/                 # logo BPJS Kesehatan & UPNVJ (sumber: Wikimedia Commons)
│  └─ figures/               # diagram SVG orisinal (bebas lisensi)
├─ supabase/
│  ├─ schema.sql             # TABEL + RLS + RPC login — jalankan di SQL Editor
│  └─ roster.template.csv    # contoh format daftar peserta
└─ package.json
```

### Mengedit konten modul

Buka `src/content/cX-*.json` — setiap modul adalah daftar blok. Tipe blok:
`text`, `callout` (variant: key/tip/warn/gold), `figure` (src/alt/caption/credit),
`mcq` (question/options/correct/rationale), `dragwords`, `matching`, `sort`,
`beforeafter`, `hotspot`, `form` (lembar kerja), `reflect`, `quiz` (gate modul).
Blok interaktif wajib punya `item_key` unik — itu kunci progresnya. Setelah mengedit: `npm run dev` untuk mengecek, lalu commit + push (deploy otomatis).

## 7. Desain & aksesibilitas

- Warna diekstrak dari logo resmi: BPJS Kesehatan (indigo `#2B3078`, hijau `#009F3C`),
  UPNVJ (kuning `#FFD200` — adaptasi kontras dari `#FFFA00`; merah `#C8102E` — adaptasi `#FE0000`).
- Kontras mengacu WCAG AA; navigasi keyboard; `prefers-reduced-motion` dihormati;
  figur memiliki `alt`; warna bukan satu-satunya pemberi makna.
- Sitasi dan lisensi tercantum pada tiap figur; bacaan WHO/ITCILO hanya ditautkan.

## 8. Rujukan bukti (dipakai dalam modul)

Freeman et al. (2014) PNAS; Mayer (2024) EPR; Trumble et al. (2024) AHSE; Morris et al. (2021) Review of Education; Alam et al. (2025) Smart Learning Environments; Jurado-Castro et al. (2023) PeerJ CS; Güngör et al. (2026) Current Psychology; Jaleniauskiene & Kasperiuniene (2023); Kepmenaker 333/2020 (SKKNI). Daftar lengkap: `Daftar_Pustaka_dan_Link_Bacaan.xlsx` pada paket ToT.
