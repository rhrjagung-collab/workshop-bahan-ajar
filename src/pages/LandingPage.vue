<script setup>
// Halaman pembuka course (pola ToxMSDT): hero, deskripsi, audiens, LO,
// daftar modul dengan status + tenggat, credits & lisensi.
import { course, modules } from '../lib/course.js'
import { store, overallPercent, moduleUnlocked } from '../lib/store.js'
import ProgressBar from '../components/ProgressBar.vue'

const unlockedAt = (i) => i === 0 || moduleUnlocked(modules[i].code)

const statusClass = s => s === 'selesai' ? 'badge-selesai' : s === 'mulai' ? 'badge-mulai' : 'badge-belum'
const statusText = s => s === 'selesai' ? 'Selesai' : s === 'mulai' ? 'Berjalan' : 'Belum mulai'
</script>

<template>
  <div class="landing">
    <section class="hero card">
      <p class="kicker">{{ course.penyelenggara }} • {{ course.kolaborasi }}</p>
      <h1>{{ course.judul_pendek }}</h1>
      <p class="lead">{{ course.deskripsi }}</p>
      <div class="hero-cta">
        <a v-if="store.session" href="#/modul/c0" class="btn btn-green">Lanjutkan belajar →</a>
        <a v-else href="#/login" class="btn btn-green">Masuk dengan kode akses</a>
        <a v-if="store.session" href="#/saya" class="btn btn-ghost">Ringkasan saya</a>
      </div>
      <div v-if="store.session" class="hero-progress">
        <ProgressBar :percent="overallPercent" label="Kemajuan Anda" />
      </div>
    </section>

    <div class="grid">
      <section class="card">
        <h2>Tujuan pembelajaran</h2>
        <p class="muted">Setelah menyelesaikan seluruh modul, Anda mampu:</p>
        <ul class="lo">
          <li v-for="(o, i) in course.outcomes" :key="i">{{ o }}</li>
        </ul>
      </section>
      <section class="card">
        <h2>Untuk siapa &amp; prasyarat</h2>
        <p><strong>Audiens:</strong> {{ course.audiens }}</p>
        <p class="muted">{{ course.tempat_tanggal }}</p>
        <ul class="lo">
          <li v-for="(p, i) in course.prasyarat" :key="i">{{ p }}</li>
        </ul>
      </section>
    </div>

    <section class="modules">
      <h2>Daftar modul <span class="muted">(± {{ course.total_menit }} menit total — kerjakan 1–2 modul per hari)</span></h2>
      <ol class="module-list">
        <li v-for="(m, mi) in modules" :key="m.code" class="card module-card" :class="{ 'card-locked': !unlockedAt(mi) }">
          <div class="module-main">
            <span class="code">{{ unlockedAt(mi) ? m.code.toUpperCase() : '🔒' }}</span>
            <div class="module-info">
              <a v-if="unlockedAt(mi)" :href="store.session ? '#/modul/' + m.code : '#/login'" class="module-title">{{ m.judul }}</a>
              <span v-else class="module-title locked-title">{{ m.judul }}</span>
              <p class="module-desc">{{ m.deskripsi }}</p>
              <p class="module-meta">
                <template v-if="unlockedAt(mi)">⏱ ±{{ m.menit }} menit • Tenggat: <strong>{{ m.tenggat_tampil }}</strong></template>
                <template v-else>Terbuka setelah modul sebelumnya 100% selesai</template>
              </p>
            </div>
          </div>
          <div class="module-side">
            <span class="badge" :class="statusClass(store.modules[m.code]?.status || 'belum')">
              {{ statusText(store.modules[m.code]?.status || 'belum') }}
            </span>
            <div class="pct">{{ store.modules[m.code]?.percent || 0 }}%</div>
          </div>
        </li>
      </ol>
    </section>

    <section class="card credits">
      <h2>Kredit &amp; lisensi</h2>
      <div class="rich" v-html="course.credits"></div>
    </section>
  </div>
</template>

<style scoped>
.hero { background: linear-gradient(135deg, var(--bpjs-indigo) 0%, var(--bpjs-indigo-dark) 100%); color: #fff; border: none; }
.hero .kicker { color: var(--upn-gold); font-weight: 700; font-size: var(--fs-small); margin: 0 0 8px; }
.hero h1 { margin: 0 0 10px; font-size: clamp(24px, 4vw, 36px); }
.hero .lead { max-width: 760px; opacity: .92; }
.hero-cta { display: flex; gap: 12px; flex-wrap: wrap; margin-top: 18px; }
.hero-cta .btn-ghost { border-color: rgba(255,255,255,.5); color: #fff; }
.hero-progress { max-width: 480px; margin-top: 22px; }
.hero-progress :deep(.label) { color: #fff; }

.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin: 18px 0; }
.grid h2 { margin-top: 0; }
.muted { color: var(--ink-faint); font-weight: 400; }
.lo { margin: 8px 0 0; padding-left: 20px; }
.lo li { margin-bottom: 8px; }

.modules h2 { margin: 30px 0 14px; }
.module-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
.module-card { display: flex; justify-content: space-between; gap: 16px; padding: 16px 20px; }
.module-main { display: flex; gap: 14px; }
.code {
  flex: none; align-self: flex-start;
  background: var(--bpjs-indigo); color: #fff; font-weight: 800; font-size: 13px;
  border-radius: 8px; padding: 5px 9px;
}
.module-title { font-weight: 700; font-size: var(--fs-h3); text-decoration: none; }
.module-title:hover { text-decoration: underline; }
.locked-title { color: var(--ink-faint); }
.card-locked { opacity: .75; background: #FBFBFC; }
.module-desc { margin: 4px 0; color: var(--ink-soft); font-size: var(--fs-small); }
.module-meta { margin: 0; font-size: 13px; color: var(--ink-faint); }
.module-side { text-align: right; flex: none; }
.pct { font-weight: 800; color: var(--bpjs-indigo); margin-top: 8px; }

.credits { margin-top: 26px; }
.credits h2 { margin-top: 0; }

@media (max-width: 760px) {
  .grid { grid-template-columns: 1fr; }
  .module-card { flex-direction: column; }
  .module-side { text-align: left; display: flex; gap: 12px; align-items: center; }
}
</style>
