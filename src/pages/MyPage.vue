<script setup>
// Ringkasan peserta: progres per modul, jawaban lembar kerja, sertifikat.
import { computed } from 'vue'
import { modules } from '../lib/course.js'
import { store, overallPercent, allModulesDone } from '../lib/store.js'
import ProgressBar from '../components/ProgressBar.vue'
import { go } from '../lib/router.js'
import { brand } from '../lib/brand.js'

if (!store.session) { go('/login') }

const statusClass = s => s === 'selesai' ? 'badge-selesai' : s === 'mulai' ? 'badge-mulai' : 'badge-belum'
const statusText = s => s === 'selesai' ? 'Selesai' : s === 'mulai' ? 'Berjalan' : 'Belum mulai'

const finalQuiz = computed(() => store.quiz.filter(r => r.quiz_kind === 'akhir' && r.is_correct).length)
const finalPassed = computed(() =>
  (store.modules['c7']?.status === 'selesai')
)
const certificateReady = computed(() => allModulesDone.value && finalPassed.value)

const today = new Date().toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })

function printCertificate() { window.print() }
</script>

<template>
  <div v-if="store.session" class="my">
    <section class="card">
      <h1>Halo, {{ store.session.nama }}</h1>
      <p class="muted">Kelompok {{ store.session.kelompok }} • {{ store.session.email }}</p>
      <div class="overall">
        <ProgressBar :percent="overallPercent" label="Kemajuan keseluruhan" />
      </div>
    </section>

    <section class="card">
      <h2>Progres per modul</h2>
      <table class="table">
        <thead>
          <tr><th>Modul</th><th>Status</th><th>Progres</th><th></th></tr>
        </thead>
        <tbody>
          <tr v-for="m in modules" :key="m.code">
            <td><strong>{{ m.code.toUpperCase() }}</strong> — {{ m.judul }}</td>
            <td><span class="badge" :class="statusClass(store.modules[m.code]?.status || 'belum')">{{ statusText(store.modules[m.code]?.status || 'belum') }}</span></td>
            <td style="min-width:140px"><ProgressBar :percent="store.modules[m.code]?.percent || 0" /></td>
            <td><a class="btn btn-ghost btn-small" :href="'#/modul/' + m.code">Buka</a></td>
          </tr>
        </tbody>
      </table>
    </section>

    <section class="card">
      <h2>Ringkasan kuis</h2>
      <p class="muted">
        Total respons tercatat: {{ store.quiz.length }}.
        Jawaban benar pada ujian akhir: {{ finalQuiz }} dari 15 soal.
      </p>
      <p class="hint">Fasilitator melihat rincian jawaban Anda melalui dashboard untuk menyiapkan pendampingan di Bogor.</p>
    </section>

    <section v-if="certificateReady" class="cert" aria-label="Sertifikat penyelesaian">
      <div class="cert-paper" id="sertifikat">
        <div class="cert-logos">
          <img :src="brand.bpjsLogo" alt="BPJS Kesehatan" />
          <span>×</span>
          <img :src="brand.upnvjLogo" alt="UPN Veteran Jakarta" />
        </div>
        <p class="cert-label">SERTIFIKAT PENYELESAIAN</p>
        <p class="cert-title">Modul Persiapan Daring</p>
        <p class="cert-course">Workshop Inovasi Bahan Ajar Digital Jaminan Sosial</p>
        <p class="cert-given">Diberikan kepada</p>
        <p class="cert-name">{{ store.session.nama }}</p>
        <p class="cert-body">
          atas penyelesaian seluruh modul persiapan daring (C0–C7) dan ujian akhir,
          sebagai persiapan Workshop Inovasi Bahan Ajar Digital Jaminan Sosial,
          Swiss-belhotel Bogor, 9–10 November 2026.
        </p>
        <p class="cert-date">Diterbitkan: {{ today }}</p>
      </div>
      <div class="actions no-print">
        <button class="btn btn-primary" @click="printCertificate">Cetak / simpan PDF sertifikat</button>
      </div>
    </section>
    <section v-else class="card locked">
      <h2>Sertifikat penyelesaian</h2>
      <p>Selesaikan seluruh modul (C0–C7) termasuk ujian akhir pada modul C7 untuk membuka sertifikat Anda.</p>
    </section>
  </div>
</template>

<style scoped>
.my { display: flex; flex-direction: column; gap: 18px; }
h1, h2 { margin-top: 0; }
.muted { color: var(--ink-soft); font-size: var(--fs-small); }
.overall { max-width: 520px; margin-top: 12px; }
.table { width: 100%; border-collapse: collapse; font-size: var(--fs-small); }
.table th, .table td { text-align: left; padding: 9px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; }
.table th { color: var(--ink-faint); font-size: 12.5px; text-transform: uppercase; letter-spacing: .05em; }

.cert { display: flex; flex-direction: column; gap: 14px; }
.cert-paper {
  background: #fff; border: 3px solid var(--bpjs-indigo);
  border-radius: var(--radius); padding: 40px 34px; text-align: center;
  box-shadow: var(--shadow-lg);
}
.cert-logos { display: flex; justify-content: center; align-items: center; gap: 12px; margin-bottom: 18px; }
.cert-logos img { height: 44px; }
.cert-logos span { color: var(--ink-faint); font-weight: 700; }
.cert-label { letter-spacing: .3em; font-weight: 800; color: var(--bpjs-green-dark); margin: 0; }
.cert-title { font-size: 26px; font-weight: 800; color: var(--bpjs-indigo); margin: 6px 0 0; }
.cert-course { font-size: var(--fs-h3); margin: 2px 0 18px; }
.cert-given { color: var(--ink-faint); margin: 0; }
.cert-name { font-size: 30px; font-weight: 800; color: var(--ink); border-bottom: 2px solid var(--upn-gold); display: inline-block; padding: 0 30px 4px; margin: 6px 0 10px; }
.cert-body { max-width: 560px; margin: 0 auto; color: var(--ink-soft); }
.cert-date { margin-top: 18px; font-size: var(--fs-small); color: var(--ink-faint); }

@media print {
  body * { visibility: hidden; }
  #sertifikat, #sertifikat * { visibility: visible; }
  #sertifikat { position: absolute; inset: 0; margin: 0; border-radius: 0; box-shadow: none; }
  .no-print { display: none !important; }
}
</style>
