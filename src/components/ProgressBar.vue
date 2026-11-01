<script setup>
const props = defineProps({
  percent: { type: Number, default: 0 },
  label: { type: String, default: '' }
})
</script>

<template>
  <div class="progress-wrap" role="progressbar" :aria-valuenow="percent" aria-valuemin="0" aria-valuemax="100">
    <div class="track">
      <div class="fill" :style="{ width: percent + '%' }"></div>
    </div>
    <span v-if="label" class="label">{{ label }} {{ percent }}%</span>
  </div>
</template>

<style scoped>
.progress-wrap { display: flex; align-items: center; gap: 10px; }
.track {
  flex: 1; height: 10px; border-radius: 999px;
  background: #E6E8EF; overflow: hidden;
}
.fill {
  height: 100%; border-radius: 999px;
  background: linear-gradient(90deg, var(--bpjs-green), #34C06A);
  transition: width .4s ease;
}
.label { font-size: 12.5px; font-weight: 700; color: var(--ink-soft); white-space: nowrap; }
</style>
