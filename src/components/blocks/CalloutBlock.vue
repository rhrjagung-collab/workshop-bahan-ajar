<script setup>
const props = defineProps({ block: { type: Object, required: true } })
</script>

<template>
  <section class="block callout" :class="block.variant || 'key'">
    <p v-if="block.title" class="callout-title">{{ block.title }}</p>
    <div class="rich" v-html="block.html"></div>
  </section>
</template>

<style scoped>
.callout {
  border-radius: var(--radius);
  padding: 16px 20px;
  margin-bottom: 26px;
  border: 1px solid transparent;
}
.callout-title { font-weight: 800; margin: 0 0 6px; }
.key { background: var(--bpjs-indigo-soft); border-color: #C9CEE6; }
.key .callout-title { color: var(--bpjs-indigo-dark); }
.tip { background: var(--bpjs-green-soft); border-color: #BFE5CC; }
.tip .callout-title { color: var(--bpjs-green-dark); }
.warn { background: var(--upn-red-soft); border-color: #F0C4CC; }
.warn .callout-title { color: var(--upn-red); }
.gold { background: var(--upn-gold-soft); border-color: #EBD98A; }
.gold .callout-title { color: var(--upn-gold-dark); }
</style>
