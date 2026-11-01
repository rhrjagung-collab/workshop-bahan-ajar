<script setup>
// Header: dua logo (BPJS Kesehatan kiri, UPNVJ kanan) + slot navigasi.
import { brand } from '../lib/brand.js'
</script>

<template>
  <header class="site-header">
    <div class="header-inner">
      <a href="#/" class="brand" aria-label="Beranda modul">
        <img class="logo-bpjs" :src="brand.bpjsLogo" alt="Logo BPJS Kesehatan" />
        <span class="x">×</span>
        <img class="logo-upnvj" :src="brand.upnvjLogo" alt="Logo UPN Veteran Jakarta" />
      </a>
      <slot />
    </div>
  </header>
</template>

<style scoped>
.site-header {
  background: var(--bpjs-indigo);
  border-bottom: 4px solid var(--upn-gold);
}
.header-inner {
  max-width: var(--maxw);
  margin: 0 auto;
  padding: 10px 18px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-wrap: wrap;
}
.brand { display: flex; align-items: center; gap: 10px; text-decoration: none; }
.logo-bpjs { height: 34px; }
.logo-upnvj { height: 38px; background: #fff; border-radius: 50%; padding: 2px; }
.x { color: rgba(255,255,255,.65); font-weight: 700; }
@media (max-width: 640px) {
  .logo-bpjs { height: 26px; }
  .logo-upnvj { height: 30px; }
}
</style>
