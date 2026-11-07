<script setup>
import { course } from '../lib/course.js'
</script>

<template>
  <footer class="site-footer">
    <div class="footer-inner">
      <p class="judul"><strong>{{ course.judul_pendek }}</strong></p>
      <p>{{ course.penyelenggara }} • {{ course.kolaborasi }}</p>
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
</style>
