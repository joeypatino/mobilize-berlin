<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("Share this group") }}</p>
    </header>

    <section class="modal-card-body is-flex" v-if="group">
      <div class="container has-text-centered">
        <b-notification
          type="is-warning"
          v-if="group.visibility !== GroupVisibility.PUBLIC"
          :closable="false"
        >
          {{
            $t(
              "This group is accessible only through it's link. Be careful where you post this link."
            )
          }}
        </b-notification>
        <b-field>
          <b-input ref="groupURLInput" :value="group.url" expanded />
          <p class="control">
            <b-tooltip
              :label="$t('URL copied to clipboard')"
              :active="showCopiedTooltip"
              always
              type="is-success"
              position="is-left"
            >
              <b-button
                type="is-primary"
                icon-right="content-paste"
                native-type="button"
                @click="copyURL"
                @keyup.enter="copyURL"
              />
            </b-tooltip>
          </p>
        </b-field>
        <div>
          <!--                  <b-icon icon="mastodon" size="is-large" type="is-primary" />-->

          <a :href="twitterShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="twitter" size="is-large" type="is-primary"
          /></a>
          <a :href="facebookShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="facebook" size="is-large" type="is-primary"
          /></a>
          <a :href="linkedInShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="linkedin" size="is-large" type="is-primary"
          /></a>
          <a
            :href="diasporaShareUrl"
            class="diaspora"
            target="_blank"
            rel="nofollow noopener"
          >
            <span data-v-5e15e80a="" class="icon has-text-primary is-large">
              <DiasporaLogo alt="diaspora-logo" />
            </span>
          </a>
          <a :href="emailShareUrl" target="_blank" rel="nofollow noopener"
            ><b-icon icon="email" size="is-large" type="is-primary"
          /></a>
        </div>
      </div>
    </section>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Vue, Ref } from "vue-property-decorator";
import { GroupVisibility } from "@/types/enums";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import DiasporaLogo from "../../assets/diaspora-icon.svg?inline";
import { displayName, IGroup } from "@/types/actor";

@Component({
  components: {
    DiasporaLogo,
  },
})
export default class ShareGroupModal extends Vue {
  @Prop({ type: Object, required: true }) group!: IGroup;

  @Ref("groupURLInput") readonly groupURLInput!: any;

  GroupVisibility = GroupVisibility;

  showCopiedTooltip = false;

  get twitterShareUrl(): string {
    return `https://twitter.com/intent/tweet?url=${encodeURIComponent(
      this.group.url
    )}&text=${displayName(this.group)}`;
  }

  get facebookShareUrl(): string {
    return `https://www.facebook.com/sharer/sharer.php?u=${encodeURIComponent(
      this.group.url
    )}`;
  }

  get linkedInShareUrl(): string {
    return `https://www.linkedin.com/shareArticle?mini=true&url=${encodeURIComponent(
      this.group.url
    )}&title=${displayName(this.group)}`;
  }

  get emailShareUrl(): string {
    return `mailto:?to=&body=${this.group.url}&subject=${displayName(
      this.group
    )}`;
  }

  get diasporaShareUrl(): string {
    return `https://share.diasporafoundation.org/?title=${encodeURIComponent(
      displayName(this.group)
    )}&url=${encodeURIComponent(this.group.url)}`;
  }

  copyURL(): void {
    this.groupURLInput.$refs.input.select();
    document.execCommand("copy");
    this.showCopiedTooltip = true;
    setTimeout(() => {
      this.showCopiedTooltip = false;
    }, 2000);
  }
}
</script>
<style lang="scss" scoped>
.diaspora span svg {
  height: 2rem;
  width: 2rem;
}
</style>