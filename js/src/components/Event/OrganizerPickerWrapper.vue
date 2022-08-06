<template>
  <div
    class="bg-white border border-gray-300 rounded-lg cursor-pointer"
    v-if="selectedActor"
  >
    <!-- If we have a current actor (inline) -->
    <div
      v-if="inline && selectedActor.id"
      class="inline box"
      dir="auto"
      @click="isComponentModalActive = true"
    >
      <div class="media">
        <div class="media-left">
          <figure class="image is-48x48" v-if="selectedActor.avatar">
            <img
              class="image is-rounded"
              :src="selectedActor.avatar.url"
              :alt="selectedActor.avatar.alt || ''"
            />
          </figure>
          <b-icon v-else size="is-large" icon="account-circle" />
        </div>
        <div class="media-content" v-if="selectedActor.name">
          <p class="is-4">{{ selectedActor.name }}</p>
          <p class="is-6 has-text-grey-dark">
            {{ `@${selectedActor.preferredUsername}` }}
          </p>
        </div>
        <div class="media-content" v-else>
          {{ `@${selectedActor.preferredUsername}` }}
        </div>
        <b-button type="is-text" @click="isComponentModalActive = true">
          {{ $t("Change") }}
        </b-button>
      </div>
    </div>
    <!-- If we have a current actor -->
    <span
      v-else-if="selectedActor.id"
      class="block"
      @click="isComponentModalActive = true"
    >
      <img
        class="image is-48x48"
        v-if="selectedActor.avatar"
        :src="selectedActor.avatar.url"
        :alt="selectedActor.avatar.alt"
      />
      <b-icon v-else size="is-large" icon="account-circle" />
    </span>
    <b-modal
      :active.sync="isComponentModalActive"
      has-modal-card
      :close-button-aria-label="$t('Close')"
    >
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{{ $t("Pick a profile or a group") }}</p>
        </header>
        <section class="modal-card-body">
          <div>
            <organizer-picker
              v-model="selectedActor"
              @input="relay"
              :restrict-moderator-level="true"
              :groupsOnly="groupsOnly"
            />
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button is-primary" type="button" @click="pickActor">
            {{ $t("Pick") }}
          </button>
        </footer>
      </div>
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue, Watch } from "vue-property-decorator";
import { IMember } from "@/types/actor/member.model";
import { IActor, IGroup, IPerson } from "../../types/actor";
import OrganizerPicker from "./OrganizerPicker.vue";
import {
  CURRENT_ACTOR_CLIENT,
  IDENTITIES,
  PERSON_GROUP_MEMBERSHIPS,
} from "../../graphql/actor";
import { Paginate } from "../../types/paginate";

@Component({
  components: { OrganizerPicker },
  apollo: {
    currentActor: CURRENT_ACTOR_CLIENT,
    personMemberships: {
      query: PERSON_GROUP_MEMBERSHIPS,
      variables() {
        return {
          id: this.currentActor?.id,
          page: 1,
          limit: 10,
          groupId: this.$route.query?.actorId,
        };
      },
      update: (data) => data.person.memberships,
    },
    identities: IDENTITIES,
  },
})
export default class OrganizerPickerWrapper extends Vue {
  @Prop({ type: Object, required: false }) value!: IActor;

  @Prop({ default: true, type: Boolean }) inline!: boolean;

  @Prop({ required: false, default: false }) groupsOnly!: boolean;

  currentActor!: IPerson;

  identities!: IPerson[];
  isComponentModalActive = false;

  membersPage = 1;

  personMemberships: Paginate<IMember> = { elements: [], total: 0 };

  @Watch("personMemberships")
  setInitialActor(): void {
    if (
      this.personMemberships?.elements[0]?.parent?.id ===
      this.$route.query?.actorId
    ) {
      this.selectedActor = this.personMemberships?.elements[0]?.parent;
    }
  }

  get selectedActor(): IActor | undefined {
    if (this.value?.id) {
      return this.value;
    }
    if (this.currentActor) {
      return this.identities.find(
        (identity) => identity.id === this.currentActor.id
      );
    }
    return undefined;
  }

  set selectedActor(selectedActor: IActor | undefined) {
    this.$emit("input", selectedActor);
  }

  async relay(group: IGroup): Promise<void> {
    this.selectedActor = group;
  }

  pickActor(): void {
    this.isComponentModalActive = false;
  }
}
</script>

<style lang="scss" scoped>
.box {
  background-color: white;
  border-radius: 6px;
  box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1),
    0 0px 0 1px rgba(10, 10, 10, 0.02);
  color: #4a4a4a;
  display: block;
  padding: 1.25rem;
}
</style>
