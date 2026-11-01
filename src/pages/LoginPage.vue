<script setup>
// Login tertutup: email + kode akses personal dari daftar peserta.
import { ref } from 'vue'
import { login } from '../lib/store.js'
import { go } from '../lib/router.js'
import { DEMO_MODE } from '../lib/config.js'

const email = ref('')
const kode = ref('')
const err = ref('')
const busy = ref(false)

async function submit() {
  err.value = ''
  busy.value = true
  try {
    await login(email.value, kode.value)
    go('/')
  } catch (e) {
    err.value = e.message || 'Login gagal.'
  } finally {
    busy.value = false
  }
}
</script>

<template>
  <div class="login-wrap">
    <div class="card login-card">
      <h1>Masuk</h1>
      <p class="muted">
        Gunakan email dan kode akses yang dikirim administrasi kegiatan.
        Bila belum menerimanya, hubungi Sri Gunda Fahriana Fahruddin (administrasi).
      </p>
      <form @submit.prevent="submit">
        <div class="field">
          <label for="email">Email</label>
          <input id="email" v-model="email" type="email" required placeholder="nama@perusahaan" autocomplete="email" />
        </div>
        <div class="field">
          <label for="kode">Kode akses</label>
          <input id="kode" v-model="kode" type="text" required placeholder="Kode dari email undangan" autocomplete="off" />
        </div>
        <p v-if="err" class="error" role="alert">{{ err }}</p>
        <button class="btn btn-primary" type="submit" :disabled="busy">
          {{ busy ? 'Memproses…' : 'Masuk' }}
        </button>
      </form>
      <p v-if="DEMO_MODE" class="demo">
        Mode demo lokal: masukkan email apa pun + kode ≥ 4 karakter.
        Tambahkan <code>@fasilitator.id</code> pada email untuk melihat dashboard fasilitator.
      </p>
    </div>
  </div>
</template>

<style scoped>
.login-wrap { display: flex; justify-content: center; padding: 30px 0; }
.login-card { width: 100%; max-width: 460px; }
h1 { margin-top: 0; }
.muted { color: var(--ink-soft); font-size: var(--fs-small); }
.field { margin: 14px 0; }
.error {
  background: var(--upn-red-soft); color: var(--upn-red);
  padding: 10px 12px; border-radius: var(--radius-sm); font-size: var(--fs-small);
}
.demo {
  margin-top: 16px; font-size: 13px; color: var(--upn-gold-dark);
  background: var(--upn-gold-soft); padding: 10px 12px; border-radius: var(--radius-sm);
}
</style>
