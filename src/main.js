import { createApp } from 'vue'
import App from './App.vue'
import './styles/tokens.css'
import './styles/blocks.css'
import { initStore } from './lib/store.js'

const app = createApp(App)
initStore().finally(() => app.mount('#app'))
