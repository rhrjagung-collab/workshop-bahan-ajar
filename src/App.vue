<script setup>
import { computed } from 'vue'
import { route, go } from './lib/router.js'
import { store, isFacilitator, logout } from './lib/store.js'
import SiteHeader from './components/SiteHeader.vue'
import SiteFooter from './components/SiteFooter.vue'
import LandingPage from './pages/LandingPage.vue'
import LoginPage from './pages/LoginPage.vue'
import ModulePage from './pages/ModulePage.vue'
import MyPage from './pages/MyPage.vue'
import DashboardPage from './pages/DashboardPage.vue'

const path = computed(() => route.path)

function onLogout() {
  logout().then(() => go('/'))
}
</script>

<template>
  <div class="app-shell">
    <SiteHeader>
      <nav class="topnav" aria-label="Navigasi utama">
        <a href="#/" :class="{ active: path === '/' }">Beranda</a>
        <template v-if="store.session">
          <a href="#/saya" :class="{ active: path === '/saya' }">Saya</a>
          <a v-if="isFacilitator" href="#/dashboard" :class="{ active: path === '/dashboard' }">Dashboard</a>
          <span class="who">{{ store.session.nama }}</span>
          <button class="btn btn-ghost btn-small" @click="onLogout">Keluar</button>
        </template>
        <a v-else href="#/login" class="btn btn-green btn-small">Masuk</a>
      </nav>
    </SiteHeader>

    <main class="main">
      <div v-if="!store.ready" class="loading">Memuat modul…</div>
      <LandingPage v-else-if="path === '/'" />
      <LoginPage v-else-if="path === '/login'" />
      <ModulePage v-else-if="path.startsWith('/modul/')" :code="path.split('/')[2]" />
      <MyPage v-else-if="path === '/saya'" />
      <DashboardPage v-else-if="path === '/dashboard'" />
      <div v-else class="card notfound">
        <h1>Halaman tidak ditemukan</h1>
        <p><a href="#/">Kembali ke beranda</a></p>
      </div>
    </main>

    <SiteFooter />
  </div>
</template>

<style scoped>
.app-shell { min-height: 100vh; display: flex; flex-direction: column; }
.main { flex: 1; width: 100%; max-width: var(--maxw); margin: 0 auto; padding: 24px 18px 60px; }
.loading { text-align: center; padding: 80px 0; color: var(--ink-soft); }
.topnav { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
.topnav a { color: #fff; text-decoration: none; font-weight: 600; font-size: var(--fs-small); opacity: .85; }
.topnav a.active, .topnav a:hover { opacity: 1; text-decoration: underline; text-underline-offset: 4px; }
.topnav .who { color: var(--upn-gold); font-weight: 700; font-size: var(--fs-small); }
.topnav .btn-ghost { border-color: rgba(255,255,255,.5); color: #fff; }
.notfound { max-width: 480px; margin: 60px auto; text-align: center; }
@media (max-width: 640px) {
  .topnav { gap: 10px; }
}
</style>
