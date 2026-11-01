<script setup>
// Pemilih komponen blok: memetakan tipe pada JSON konten ke komponen Vue.
import TextBlock from './TextBlock.vue'
import CalloutBlock from './CalloutBlock.vue'
import FigureBlock from './FigureBlock.vue'
import McqBlock from './McqBlock.vue'
import DragWordsBlock from './DragWordsBlock.vue'
import MatchingBlock from './MatchingBlock.vue'
import SortBlock from './SortBlock.vue'
import BeforeAfterBlock from './BeforeAfterBlock.vue'
import HotspotBlock from './HotspotBlock.vue'
import FormBlock from './FormBlock.vue'
import ReflectBlock from './ReflectBlock.vue'
import QuizGateBlock from './QuizGateBlock.vue'

const map = {
  text: TextBlock,
  callout: CalloutBlock,
  figure: FigureBlock,
  mcq: McqBlock,
  dragwords: DragWordsBlock,
  matching: MatchingBlock,
  sort: SortBlock,
  beforeafter: BeforeAfterBlock,
  hotspot: HotspotBlock,
  form: FormBlock,
  reflect: ReflectBlock,
  quiz: QuizGateBlock
}

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})
</script>

<template>
  <component :is="map[block.type]" :block="block" :module-code="moduleCode" />
</template>
