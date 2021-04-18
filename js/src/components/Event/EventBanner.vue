<template>
  <div class="banner-container">
    <blurhash-img-wrapper :picture="picture" />
  </div>
</template>
<script lang="ts">
import { IMedia } from "@/types/media.model";
import { PropType } from "vue";
import { Component, Prop, Vue } from "vue-property-decorator";
import BlurhashImgWrapper from "../Image/BlurhashImgWrapper.vue";

@Component({
  components: {
    BlurhashImgWrapper,
  },
})
export default class EventBanner extends Vue {
  @Prop({ default: null, type: Object as PropType<IMedia> })
  picture!: IMedia | null;
}
</script>
<style lang="scss" scoped>
.banner-container {
  display: flex;
  justify-content: center;
  height: 30vh;
}
::v-deep img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 50% 50%;
}
</style>
