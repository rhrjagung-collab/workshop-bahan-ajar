import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// base './' agar hasil build bisa di-deploy di root maupun subpath (Vercel/GitHub Pages)
export default defineConfig({
  base: './',
  plugins: [vue()],
  build: {
    target: 'es2019'
  }
})
