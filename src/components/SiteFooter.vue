<script setup>
import { course } from '../lib/course.js'
import { DEMO_MODE } from '../lib/config.js'
</script>

<template>
  <footer class="site-footer">
    <div class="footer-inner">
      <p class="judul"><strong>{{ course.judul }}</strong></p>
      <p>
        {{ course.penyelenggara }} • {{ course.kolaborasi }} •
        {{ course.tempat_tanggal }} • Modul persiapan daring v1.0
      </p>
      <p class="lisensi">
        Sitasi dan lisensi setiap figur tercantum pada masing-masing figur.
        Bacaan WHO/ITCILO hanya ditautkan ke sumber resmi.
      </p>
      <p v-if="DEMO_MODE" class="demo-note">
        Mode demo lokal — progres tersimpan di peramban ini saja. Konfigurasikan Supabase untuk penyimpanan permanen (lihat README).
      </p>
    </div>
  </footer>
</template>

<style scoped>
.site-footer {
  background: var(--bpjs-indigo-dark);
  color: #D9DCEB;
  font-size: var(--fs-small);
  margin-top: auto;
}
.footer-inner { max-width: var(--maxw); margin: 0 auto; padding: 22px 18px; }
.judul { margin: 0 0 6px; color: #fff; }
p { margin: 4px 0; }
.lisensi { opacity: .75; }
.demo-note {
  margin-top: 10px; padding: 8px 12px; border-radius: var(--radius-sm);
  background: rgba(255, 210, 0, .12); color: var(--upn-gold);
}
</style>
