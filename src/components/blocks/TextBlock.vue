<script setup>
const props = defineProps({ block: { type: Object, required: true } })
</script>

<template>
  <section class="block rich" v-html="block.html"></section>
</template>
