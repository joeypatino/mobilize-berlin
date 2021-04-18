<template>
  <div class="wrapper" v-bind="$attrs">
    <div class="relative container">
      <blurhash-img
        v-if="pictureOrDefault.metadata.blurhash"
        :hash="pictureOrDefault.metadata.blurhash"
        class="top-0 left-0"
      />
    </div>
  </div>
</template>

<script lang="ts">
import { IMedia } from "@/types/media.model";
import { Prop, Component, Vue } from "vue-property-decorator";
import { PropType } from "vue";
import BlurhashImg from "./BlurhashImg.vue";

const DEFAULT_CARD_URL = "/img/mobilizon_default_card.png";
const DEFAULT_BLURHASH = "MCHKI4El-P-U}+={R-WWoes,Iu-P=?R,xD";
const DEFAULT_WIDTH = 630;
const DEFAULT_HEIGHT = 350;
const DEFAULT_PICTURE = {
  url: DEFAULT_CARD_URL,
  metadata: {
    width: DEFAULT_WIDTH,
    height: DEFAULT_HEIGHT,
    blurhash: DEFAULT_BLURHASH,
  },
};

@Component({
  components: {
    BlurhashImg,
  },
})
export default class BlurhashImgWrapper extends Vue {
  @Prop({ required: false, type: Object as PropType<IMedia | null> })
  picture!: IMedia | null;

  get pictureOrDefault(): Partial<IMedia> {
    if (this.picture === null) {
      return DEFAULT_PICTURE;
    }
    return {
      url: this?.picture?.url,
      metadata: {
        width: this?.picture?.metadata?.width,
        height: this?.picture?.metadata?.height,
        blurhash: this?.picture?.metadata?.blurhash,
      },
    };
  }
}
</script>
<style lang="scss" scoped>
.relative {
  position: relative;
}
.absolute {
  position: absolute;
}
.top-0 {
  top: 0;
}
.left-0 {
  left: 0;
}
.wrapper,
.container {
  display: flex;
  flex: 1;
}
img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 50% 50%;
}
</style>
