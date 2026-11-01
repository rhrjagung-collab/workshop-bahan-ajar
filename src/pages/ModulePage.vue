<script setup>
// Player modul: sidebar daftar modul + status, konten scroll berisi blok,
// navigasi Lanjut, dan panel "modul selesai".
import { computed, ref, watch } from 'vue'
import { modules, getModule, nextModule, requiredBlocks, isBlockDone } from '../lib/course.js'
import { store, getItemState, syncModuleProgress } from '../lib/store.js'
import { go } from '../lib/router.js'
import BlockRenderer from '../components/blocks/BlockRenderer.vue'
import ProgressBar from '../components/ProgressBar.vue'

const props = defineProps({ code: { type: String, required: true } })
const mod = computed(() => getModule(props.code))
const idx = computed(() => modules.findIndex(m => m.code === props.code))
const next = computed(() => nextModule(props.code))
const prev = computed(() => idx.value > 0 ? modules[idx.value - 1] : null)

const percent = computed(() => store.modules[props.code]?.percent || 0)
const done = computed(() => store.modules[props.code]?.status === 'selesai')

const blocks = computed(() => mod.value?.blocks || [])

const statusClass = s => s === 'selesai' ? 'badge-selesai' : s === 'mulai' ? 'badge-mulai' : 'badge-belum'
const statusText = s => s === 'selesai' ? 'Selesai' : s === 'mulai' ? 'Berjalan' : 'Belum mulai'

// Lindungi modul: harus login
if (!store.session) { go('/login') }

// Sinkronkan progres saat modul dibuka (bila ada blok selesai namun modul belum terhitung)
watch(() => props.code, () => { syncModuleProgress(props.code) }, { immediate: true })

function menuDone(m) { return store.modules[m.code]?.status === 'selesai' }
</script>

<template>
  <div v-if="mod" class="player">
    <aside class="sidebar card" aria-label="Daftar modul">
      <div class="side-head">
        <div class="side-progress">
          <ProgressBar
            :percent="Math.round(modules.reduce((a, m) => a + (store.modules[m.code]?.percent || 0), 0) / modules.length)"
            label="Keseluruhan"
          />
        </div>
      </div>
      <ol class="side-list">
        <li v-for="m in modules" :key="m.code" :class="{ current: m.code === props.code }">
          <a :href="'#/modul/' + m.code" class="side-link">
            <span class="side-code">{{ m.code.toUpperCase() }}</span>
            <span class="side-title">
              {{ m.judul }}
              <span class="side-status" :class="statusClass(store.modules[m.code]?.status || 'belum')">
                {{ menuDone(m) ? '✓' : (store.modules[m.code]?.percent || 0) + '%' }}
              </span>
            </span>
          </a>
        </li>
      </ol>
    </aside>

    <article class="content">
      <header class="mod-header card">
        <p class="crumb">Modul {{ mod.code.toUpperCase() }} • ±{{ mod.menit }} menit • Tenggat {{ mod.tenggat_tampil }}</p>
        <h1>{{ mod.judul }}</h1>
        <p class="mod-desc">{{ mod.deskripsi }}</p>
        <ProgressBar :percent="percent" label="Progres modul" />
      </header>

      <BlockRenderer v-for="(b, i) in blocks" :key="mod.code + '-' + i" :block="b" :module-code="mod.code" />

      <section v-if="done" class="card finish" aria-label="Modul selesai">
        <h2>✓ Modul {{ mod.code.toUpperCase() }} selesai</h2>
        <p>{{ mod.penutup }}</p>
        <div class="actions">
          <a v-if="next" class="btn btn-green" :href="'#/modul/' + next.code">Lanjut ke {{ next.code.toUpperCase() }} — {{ next.judul }} →</a>
          <a v-else class="btn btn-green" href="#/saya">Lihat ringkasan &amp; sertifikat →</a>
          <a v-if="prev" class="btn btn-ghost" :href="'#/modul/' + prev.code">← Kembali ke {{ prev.code.toUpperCase() }}</a>
        </div>
      </section>
      <section v-else class="card finish-locked">
        <h2>{{ requiredBlocks(mod).length - requiredBlocks(mod).filter(b => isBlockDone(getItemState(mod.code, b.item_key))).length }} aktivitas lagi untuk menyelesaikan modul</h2>
        <p>Selesaikan seluruh latihan dan kuis pada halaman ini. Progres tersimpan otomatis — Anda boleh berhenti dan melanjutkan kapan saja.</p>
        <a v-if="next" class="btn btn-ghost btn-small" :href="'#/modul/' + next.code">Buka modul berikutnya saja →</a>
      </section>
    </article>
  </div>

  <div v-else class="card notfound">
    <h1>Modul tidak ditemukan</h1>
    <p><a href="#/">Kembali ke beranda</a></p>
  </div>
</template>

<style scoped>
.player { display: grid; grid-template-columns: 280px 1fr; gap: 20px; align-items: start; }
.sidebar { position: sticky; top: 16px; padding: 16px; }
.side-list { list-style: none; margin: 12px 0 0; padding: 0; display: flex; flex-direction: column; gap: 2px; }
.side-link {
  display: flex; gap: 10px; align-items: flex-start;
  text-decoration: none; color: var(--ink);
  padding: 8px 10px; border-radius: var(--radius-sm);
  font-size: 14px; line-height: 1.4;
}
.side-link:hover { background: var(--bpjs-indigo-soft); }
li.current .side-link { background: var(--bpjs-indigo); color: #fff; }
li.current .side-title { color: #fff; }
li.current .side-code { background: var(--upn-gold); color: var(--bpjs-indigo-dark); }
.side-code {
  flex: none; font-size: 11.5px; font-weight: 800;
  background: var(--bpjs-indigo-soft); color: var(--bpjs-indigo-dark);
  border-radius: 6px; padding: 2px 7px; margin-top: 2px;
}
.side-title { flex: 1; font-weight: 600; }
.side-status { float: right; font-size: 12px; }

.mod-header { margin-bottom: 22px; }
.crumb { font-size: 13px; color: var(--ink-faint); font-weight: 600; margin: 0 0 4px; }
.mod-header h1 { margin: 0 0 6px; font-size: clamp(22px, 3vw, 30px); }
.mod-desc { color: var(--ink-soft); margin: 0 0 16px; }

.finish { border-left: 6px solid var(--bpjs-green); }
.finish h2 { margin-top: 0; color: var(--bpjs-green-dark); }
.finish-locked { border-left: 6px solid var(--upn-gold); }
.finish-locked h2 { margin-top: 0; font-size: var(--fs-h3); }
.actions { display: flex; gap: 10px; flex-wrap: wrap; margin-top: 14px; }
.notfound { max-width: 480px; margin: 60px auto; text-align: center; }

@media (max-width: 900px) {
  .player { grid-template-columns: 1fr; }
  .sidebar { position: static; }
}
</style>
