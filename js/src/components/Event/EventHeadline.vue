<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <div>{{ $t("Headline picture") }}</div>
      <button type="button" class="delete" @click="$emit('close')" />
    </header>
    <div class="modal-card-body">
      <section style="background-color: white">
        <p>bla{{ src }}</p>
        <img :src="image" />
      </section>
    </div>
    <footer class="modal-card-foot"></footer>
  </div>
</template>
<script lang="ts">
import { Vue, Prop } from "vue-property-decorator";

export default class EventHeadline extends Vue {
  @Prop({ required: true, type: String }) image!: string;
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;
.modal-card-head {
  display: flex;
}
button.delete {
  margin-left: auto;
  @include margin-right(1rem);
}
</style>
