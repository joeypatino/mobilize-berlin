<template>
  <div class="container is-widescreen">
    <div class="header">
      <nav class="breadcrumb" :aria-label="$t('Breadcrumbs')">
        <ul>
          <li>
            <router-link :to="{ name: RouteName.MY_GROUPS }">{{
              $t("My groups")
            }}</router-link>
          </li>
          <li class="is-active">
            <router-link
              aria-current-value="location"
              v-if="group && group.preferredUsername"
              :to="{
                name: RouteName.GROUP,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              >{{ group.name }}</router-link
            >
            <b-skeleton v-else :animated="true"></b-skeleton>
          </li>
        </ul>
      </nav>
      <invitations
        v-if="isCurrentActorAnInvitedGroupMember"
        :invitations="[groupMember]"
        @acceptInvitation="acceptInvitation"
        @reject-invitation="rejectInvitation"
      />
      <b-message v-if="isCurrentActorARejectedGroupMember" type="is-danger">
        {{ $t("You have been removed from this group's members.") }}
      </b-message>
      <b-message
        v-if="
          isCurrentActorAGroupMember &&
          isCurrentActorARecentMember &&
          isCurrentActorOnADifferentDomainThanGroup
        "
        type="is-info"
      >
        {{
          $t(
            "Since you are a new member, private content can take a few minutes to appear."
          )
        }}
      </b-message>
      <header class="block-container presentation" v-if="group">
        <div class="banner-container">
          <lazy-image-wrapper :picture="group.banner" />
        </div>
        <div class="header">
          <div class="avatar-container">
            <figure class="image is-128x128" v-if="group.avatar">
              <img class="is-rounded" :src="group.avatar.url" alt="" />
            </figure>
            <b-icon v-else size="is-large" icon="account-group" />
          </div>
          <div class="title-container">
            <h1 v-if="group.name">{{ group.name }}</h1>
            <b-skeleton v-else :animated="true" />
            <small class="has-text-grey-dark" v-if="group.preferredUsername"
              >@{{ usernameWithDomain(group) }}</small
            >
            <b-skeleton v-else :animated="true" />
            <br />
          </div>
          <div class="group-metadata">
            <div
              class="block-column members"
              v-if="isCurrentActorAGroupMember && !previewPublic"
            >
              <div>
                <figure
                  class="image is-32x32"
                  :title="
                    $t(`@{username} ({role})`, {
                      username: usernameWithDomain(member.actor),
                      role: member.role,
                    })
                  "
                  v-for="member in members"
                  :key="member.actor.id"
                >
                  <img
                    class="is-rounded"
                    :src="member.actor.avatar.url"
                    v-if="member.actor.avatar"
                    alt
                  />
                  <b-icon v-else size="is-medium" icon="account-circle" />
                </figure>
              </div>
              <p>
                {{
                  $tc("{count} members", group.members.total, {
                    count: group.members.total,
                  })
                }}
                <router-link
                  v-if="isCurrentActorAGroupAdmin"
                  :to="{
                    name: RouteName.GROUP_MEMBERS_SETTINGS,
                    params: { preferredUsername: usernameWithDomain(group) },
                  }"
                  >{{ $t("Add / Remove…") }}</router-link
                >
              </p>
            </div>
            <div class="buttons">
              <b-button
                outlined
                icon-left="timeline-text"
                v-if="isCurrentActorAGroupMember && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.TIMELINE,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                >{{ $t("Activity") }}</b-button
              >
              <b-button
                outlined
                icon-left="cog"
                v-if="isCurrentActorAGroupAdmin && !previewPublic"
                tag="router-link"
                :to="{
                  name: RouteName.GROUP_PUBLIC_SETTINGS,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                >{{ $t("Group settings") }}</b-button
              >
              <b-tooltip
                v-if="
                  (!isCurrentActorAGroupMember || previewPublic) &&
                  group.openness !== Openness.OPEN
                "
                :label="$t('This group is invite-only')"
                position="is-bottom"
              >
                <b-button disabled type="is-primary">{{
                  $t("Join group")
                }}</b-button></b-tooltip
              >
              <b-button
                v-else-if="
                  (!isCurrentActorAGroupMember || previewPublic) &&
                  currentActor.id
                "
                @click="joinGroup"
                type="is-primary"
                :disabled="previewPublic"
                >{{ $t("Join group") }}</b-button
              >
              <b-button
                tag="router-link"
                :to="{
                  name: RouteName.GROUP_JOIN,
                  params: { preferredUsername: usernameWithDomain(group) },
                }"
                v-else-if="!isCurrentActorAGroupMember || previewPublic"
                :disabled="previewPublic"
                type="is-primary"
                >{{ $t("Join group") }}</b-button
              >
              <b-button
                outlined
                icon-left="share"
                @click="triggerShare()"
                v-if="!isCurrentActorAGroupMember || previewPublic"
              >
                {{ $t("Share") }}
              </b-button>
              <b-dropdown
                class="menu-dropdown"
                position="is-bottom-left"
                aria-role="menu"
              >
                <b-button
                  slot="trigger"
                  outlined
                  role="button"
                  icon-left="dots-horizontal"
                  :aria-label="$t('Other actions')"
                />
                <b-dropdown-item
                  aria-role="menuitem"
                  v-if="isCurrentActorAGroupMember || previewPublic"
                >
                  <b-switch v-model="previewPublic">{{
                    $t("Public preview")
                  }}</b-switch>
                </b-dropdown-item>
                <b-dropdown-item
                  v-if="!previewPublic && isCurrentActorAGroupMember"
                  aria-role="menuitem"
                  @click="triggerShare()"
                >
                  <span>
                    <b-icon icon="share" />
                    {{ $t("Share") }}
                  </span>
                </b-dropdown-item>
                <hr
                  class="dropdown-divider"
                  v-if="isCurrentActorAGroupMember"
                />
                <b-dropdown-item has-link aria-role="menuitem">
                  <a
                    :href="`@${preferredUsername}/feed/atom`"
                    :title="$t('Atom feed for events and posts')"
                  >
                    <b-icon icon="rss" />
                    {{ $t("RSS/Atom Feed") }}
                  </a>
                </b-dropdown-item>
                <b-dropdown-item has-link aria-role="menuitem">
                  <a
                    :href="`@${preferredUsername}/feed/ics`"
                    :title="$t('ICS feed for events')"
                  >
                    <b-icon icon="calendar-sync" />
                    {{ $t("ICS/WebCal Feed") }}
                  </a>
                </b-dropdown-item>
                <hr class="dropdown-divider" />
                <b-dropdown-item
                  v-if="ableToReport"
                  aria-role="menuitem"
                  @click="isReportModalActive = true"
                >
                  <span>
                    <b-icon icon="flag" />
                    {{ $t("Report") }}
                  </span>
                </b-dropdown-item>
                <b-dropdown-item
                  aria-role="menuitem"
                  v-if="isCurrentActorAGroupMember && !previewPublic"
                  @click="leaveGroup"
                >
                  <span>
                    <b-icon icon="exit-to-app" />
                    {{ $t("Leave") }}
                  </span>
                </b-dropdown-item>
              </b-dropdown>
            </div>
          </div>
        </div>
      </header>
    </div>
    <div
      v-if="isCurrentActorAGroupMember && !previewPublic"
      class="block-container"
    >
      <!-- Private things -->
      <div class="block-column">
        <!-- Group discussions -->
        <group-section
          :title="$t('Discussions')"
          icon="chat"
          :route="{
            name: RouteName.DISCUSSION_LIST,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div v-if="group.discussions.total > 0">
              <discussion-list-item
                v-for="discussion in group.discussions.elements"
                :key="discussion.id"
                :discussion="discussion"
              />
            </div>
            <empty-content v-else icon="chat" :inline="true">
              {{ $t("No discussions yet") }}
            </empty-content>
          </template>
          <template v-slot:create>
            <router-link
              :to="{
                name: RouteName.CREATE_DISCUSSION,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-primary"
              >{{ $t("+ Start a discussion") }}</router-link
            >
          </template>
        </group-section>
        <!-- Resources -->
        <group-section
          :title="$t('Resources')"
          icon="link"
          :route="{
            name: RouteName.RESOURCE_FOLDER_ROOT,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div v-if="group.resources.elements.length > 0">
              <div
                v-for="resource in group.resources.elements"
                :key="resource.id"
              >
                <resource-item
                  :resource="resource"
                  v-if="resource.type !== 'folder'"
                  :inline="true"
                />
                <folder-item
                  :resource="resource"
                  :group="group"
                  v-else
                  :inline="true"
                />
              </div>
            </div>
            <empty-content v-else icon="link" :inline="true">
              {{ $t("No resources yet") }}
            </empty-content>
          </template>
          <template v-slot:create>
            <router-link
              :to="{
                name: RouteName.RESOURCE_FOLDER_ROOT,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-primary"
              >{{ $t("+ Add a resource") }}</router-link
            >
          </template>
        </group-section>
      </div>
      <!-- Public things -->
      <div class="block-column">
        <!-- Events -->
        <group-section
          :title="$t('Events')"
          icon="calendar"
          :privateSection="false"
          :route="{
            name: RouteName.GROUP_EVENTS,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div
              class="organized-events-wrapper"
              v-if="group && group.organizedEvents.total > 0"
            >
              <EventMinimalistCard
                v-for="event in group.organizedEvents.elements"
                :event="event"
                :key="event.uuid"
                class="organized-event"
              />
            </div>
            <empty-content v-else-if="group" icon="calendar" :inline="true">
              {{ $t("No public upcoming events") }}
            </empty-content>
            <b-skeleton animated v-else></b-skeleton>
          </template>
          <template v-slot:create>
            <router-link
              v-if="isCurrentActorAGroupModerator"
              :to="{
                name: RouteName.CREATE_EVENT,
                query: { actorId: group.id },
              }"
              class="button is-primary"
              >{{ $t("+ Create an event") }}</router-link
            >
          </template>
        </group-section>
        <!-- Posts -->
        <group-section
          :title="$t('Public page')"
          icon="bullhorn"
          :privateSection="false"
          :route="{
            name: RouteName.POSTS,
            params: { preferredUsername: usernameWithDomain(group) },
          }"
        >
          <template v-slot:default>
            <div v-if="group.posts.total > 0" class="posts-wrapper">
              <post-list-item
                v-for="post in group.posts.elements"
                :key="post.id"
                :post="post"
              />
            </div>
            <empty-content v-else-if="group" icon="bullhorn" :inline="true">
              {{ $t("No posts yet") }}
            </empty-content>
          </template>
          <template v-slot:create>
            <router-link
              v-if="isCurrentActorAGroupModerator"
              :to="{
                name: RouteName.POST_CREATE,
                params: { preferredUsername: usernameWithDomain(group) },
              }"
              class="button is-primary"
              >{{ $t("+ Post a public message") }}</router-link
            >
          </template>
        </group-section>
      </div>
    </div>
    <b-message v-else-if="!group && $apollo.loading === false" type="is-danger">
      {{ $t("No group found") }}
    </b-message>
    <div v-else-if="group" class="public-container">
      <aside class="group-metadata">
        <div class="sticky">
          <event-metadata-block :title="$t('Members')" icon="account-group">
            {{
              $tc("{count} members", group.members.total, {
                count: group.members.total,
              })
            }}
          </event-metadata-block>
          <event-metadata-block
            v-if="physicalAddress"
            :title="$t('Location')"
            :icon="
              physicalAddress ? physicalAddress.poiInfos.poiIcon.icon : 'earth'
            "
          >
            <div class="address-wrapper">
              <span v-if="!physicalAddress">{{
                $t("No address defined")
              }}</span>
              <div class="address" v-if="physicalAddress">
                <div>
                  <address>
                    <p
                      class="addressDescription"
                      :title="physicalAddress.poiInfos.name"
                    >
                      {{ physicalAddress.poiInfos.name }}
                    </p>
                    <p class="has-text-grey-dark">
                      {{ physicalAddress.poiInfos.alternativeName }}
                    </p>
                  </address>
                </div>
                <span
                  class="map-show-button"
                  @click="showMap = !showMap"
                  v-if="physicalAddress.geom"
                  >{{ $t("Show map") }}</span
                >
              </div>
            </div>
          </event-metadata-block>
        </div>
      </aside>
      <div class="main-content">
        <section>
          <subtitle>{{ $t("About") }}</subtitle>
          <div
            v-html="group.summary"
            v-if="group.summary && group.summary !== '<p></p>'"
          />
          <empty-content v-else-if="group" icon="image-text" :inline="true">
            {{ $t("This group doesn't have a description yet.") }}
          </empty-content>
        </section>
        <section>
          <subtitle>{{ $t("Upcoming events") }}</subtitle>
          <div
            class="organized-events-wrapper"
            v-if="group && organizedEvents.elements.length > 0"
          >
            <EventMinimalistCard
              v-for="event in organizedEvents.elements"
              :event="event"
              :key="event.uuid"
              class="organized-event"
            />
          </div>
          <empty-content v-else-if="group" icon="calendar" :inline="true">
            {{ $t("No public upcoming events") }}
          </empty-content>
          <b-skeleton animated v-else-if="$apollo.loading"></b-skeleton>
          <router-link
            v-if="organizedEvents.total > 0"
            :to="{
              name: RouteName.GROUP_EVENTS,
              params: { preferredUsername: usernameWithDomain(group) },
              query: { future: organizedEvents.elements.length > 0 },
            }"
            >{{ $t("View all events") }}</router-link
          >
        </section>
        <section>
          <subtitle>{{ $t("Latest posts") }}</subtitle>
          <div v-if="posts.elements.length > 0" class="posts-wrapper">
            <post-list-item
              v-for="post in posts.elements"
              :key="post.id"
              :post="post"
            />
          </div>
          <empty-content v-else-if="group" icon="bullhorn" :inline="true">
            {{ $t("No posts yet") }}
          </empty-content>
          <b-skeleton animated v-else-if="$apollo.loading"></b-skeleton>
          <router-link
            v-if="posts.total > 0"
            :to="{
              name: RouteName.POSTS,
              params: { preferredUsername: usernameWithDomain(group) },
            }"
            >{{ $t("View all posts") }}</router-link
          >
        </section>
      </div>
      <b-modal
        v-if="physicalAddress && physicalAddress.geom"
        :active.sync="showMap"
      >
        <div class="map">
          <map-leaflet
            :coords="physicalAddress.geom"
            :marker="{
              text: physicalAddress.fullName,
              icon: physicalAddress.poiInfos.poiIcon.icon,
            }"
          />
        </div>
      </b-modal>
    </div>
    <b-modal
      :active.sync="isReportModalActive"
      has-modal-card
      ref="reportModal"
      v-if="group"
    >
      <report-modal
        :on-confirm="reportGroup"
        :title="$t('Report this group')"
        :outside-domain="group.domain"
        @close="$refs.reportModal.close()"
      />
    </b-modal>
    <b-modal
      v-if="group"
      :active.sync="isShareModalActive"
      has-modal-card
      ref="shareModal"
    >
      <share-group-modal :group="group" />
    </b-modal>
  </div>
</template>

<script lang="ts">
import { Component, Prop, Watch } from "vue-property-decorator";
import EventCard from "@/components/Event/EventCard.vue";
import { displayName, IActor, usernameWithDomain } from "@/types/actor";
import Subtitle from "@/components/Utils/Subtitle.vue";
import CompactTodo from "@/components/Todo/CompactTodo.vue";
import EventMinimalistCard from "@/components/Event/EventMinimalistCard.vue";
import DiscussionListItem from "@/components/Discussion/DiscussionListItem.vue";
import PostListItem from "@/components/Post/PostListItem.vue";
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import { Address } from "@/types/address.model";
import Invitations from "@/components/Group/Invitations.vue";
import addMinutes from "date-fns/addMinutes";
import { CONFIG } from "@/graphql/config";
import { CREATE_REPORT } from "@/graphql/report";
import { IReport } from "@/types/report.model";
import { IConfig } from "@/types/config.model";
import GroupMixin from "@/mixins/group";
import { mixins } from "vue-class-component";
import { JOIN_GROUP } from "@/graphql/member";
import { MemberRole, Openness, PostVisibility } from "@/types/enums";
import { IMember } from "@/types/actor/member.model";
import RouteName from "../../router/name";
import GroupSection from "../../components/Group/GroupSection.vue";
import ReportModal from "../../components/Report/ReportModal.vue";
import { PERSON_MEMBERSHIP_GROUP } from "@/graphql/actor";
import { LEAVE_GROUP } from "@/graphql/group";
import LazyImageWrapper from "../../components/Image/LazyImageWrapper.vue";
import EventMetadataBlock from "../../components/Event/EventMetadataBlock.vue";
import EmptyContent from "../../components/Utils/EmptyContent.vue";
import { Paginate } from "@/types/paginate";
import { IEvent } from "@/types/event.model";
import { IPost } from "@/types/post.model";

@Component({
  apollo: {
    config: CONFIG,
  },
  components: {
    DiscussionListItem,
    PostListItem,
    EventMinimalistCard,
    CompactTodo,
    Subtitle,
    EventCard,
    FolderItem,
    ResourceItem,
    GroupSection,
    Invitations,
    ReportModal,
    LazyImageWrapper,
    EventMetadataBlock,
    EmptyContent,
    "map-leaflet": () =>
      import(/* webpackChunkName: "map" */ "../../components/Map.vue"),
    ShareGroupModal: () =>
      import(
        /* webpackChunkName: "shareGroupModal" */ "../../components/Group/ShareGroupModal.vue"
      ),
  },
  metaInfo() {
    return {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      title: this.groupTitle,
      meta: [
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        { name: "description", content: this.groupSummary },
      ],
    };
  },
})
export default class Group extends mixins(GroupMixin) {
  @Prop({ type: String, required: true }) preferredUsername!: string;

  config!: IConfig;

  loading = true;

  RouteName = RouteName;

  usernameWithDomain = usernameWithDomain;

  Openness = Openness;

  showMap = false;

  isReportModalActive = false;

  isShareModalActive = false;

  previewPublic = false;

  @Watch("currentActor")
  watchCurrentActor(currentActor: IActor, oldActor: IActor): void {
    if (currentActor.id && oldActor && currentActor.id !== oldActor.id) {
      this.$apollo.queries.group.refetch();
    }
  }

  async joinGroup(): Promise<void> {
    const [group, currentActorId] = [
      usernameWithDomain(this.group),
      this.currentActor.id,
    ];
    this.$apollo.mutate({
      mutation: JOIN_GROUP,
      variables: {
        groupId: this.group.id,
      },
      refetchQueries: [
        {
          query: PERSON_MEMBERSHIP_GROUP,
          variables: {
            id: currentActorId,
            group,
          },
        },
      ],
    });
  }

  async leaveGroup(): Promise<void> {
    try {
      const [group, currentActorId] = [
        usernameWithDomain(this.group),
        this.currentActor.id,
      ];
      await this.$apollo.mutate({
        mutation: LEAVE_GROUP,
        variables: {
          groupId: this.group.id,
        },
        refetchQueries: [
          {
            query: PERSON_MEMBERSHIP_GROUP,
            variables: {
              id: currentActorId,
              group,
            },
          },
        ],
      });
    } catch (error) {
      if (error.graphQLErrors && error.graphQLErrors.length > 0) {
        this.$notifier.error(error.graphQLErrors[0].message);
      }
    }
  }

  acceptInvitation(): void {
    if (this.groupMember) {
      const index = this.person.memberships.elements.findIndex(
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        ({ id }: IMember) => id === this.groupMember.id
      );
      const member = this.groupMember;
      member.role = MemberRole.MEMBER;
      this.person.memberships.elements.splice(index, 1, member);
      this.$apollo.queries.group.refetch();
    }
  }

  rejectInvitation({ id: memberId }: { id: string }): void {
    const index = this.person.memberships.elements.findIndex(
      (membership) =>
        membership.role === MemberRole.INVITED && membership.id === memberId
    );
    if (index > -1) {
      this.person.memberships.elements.splice(index, 1);
      this.person.memberships.total -= 1;
    }
  }

  async reportGroup(content: string, forward: boolean): Promise<void> {
    this.isReportModalActive = false;
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.$refs.reportModal.close();
    const groupTitle = this.group.name || usernameWithDomain(this.group);
    try {
      await this.$apollo.mutate<IReport>({
        mutation: CREATE_REPORT,
        variables: {
          reportedId: this.group.id,
          content,
          forward,
        },
      });
      this.$notifier.success(
        this.$t("Group {groupTitle} reported", { groupTitle }) as string
      );
    } catch (error) {
      console.error(error);
      this.$notifier.error(
        this.$t("Error while reporting group {groupTitle}", {
          groupTitle,
        }) as string
      );
    }
  }

  triggerShare(): void {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-start
    if (navigator.share) {
      navigator
        // eslint-disable-next-line @typescript-eslint/ban-ts-comment
        // @ts-ignore
        .share({
          title: displayName(this.group),
          url: this.group.url,
        })
        .then(() => console.log("Successful share"))
        .catch((error: any) => console.log("Error sharing", error));
    } else {
      this.isShareModalActive = true;
      // send popup
    }
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore-end
  }

  get groupTitle(): undefined | string {
    return this.group?.name || this.group?.preferredUsername;
  }

  get groupSummary(): undefined | string {
    return this.group?.summary;
  }

  get groupMember(): IMember | undefined {
    if (this.person?.memberships?.total > 0) {
      return this.person?.memberships?.elements[0];
    }
    return undefined;
  }

  get groupMemberships(): (string | undefined)[] {
    return this.person?.memberships?.elements
      .filter(
        (membership: IMember) =>
          ![
            MemberRole.REJECTED,
            MemberRole.NOT_APPROVED,
            MemberRole.INVITED,
          ].includes(membership.role)
      )
      .map(({ parent: { id } }) => id);
  }

  @Watch("isCurrentActorAGroupMember")
  refetchGroupData(): void {
    this.$apollo.queries.group.refetch();
  }

  get isCurrentActorAGroupMember(): boolean {
    return (
      this.groupMemberships !== undefined &&
      this.groupMemberships.includes(this.group.id)
    );
  }

  get isCurrentActorARejectedGroupMember(): boolean {
    return (
      this.person &&
      this.person.memberships.elements
        .filter((membership) => membership.role === MemberRole.REJECTED)
        .map(({ parent: { id } }) => id)
        .includes(this.group.id)
    );
  }

  get isCurrentActorAnInvitedGroupMember(): boolean {
    return (
      this.person &&
      this.person.memberships.elements
        .filter((membership) => membership.role === MemberRole.INVITED)
        .map(({ parent: { id } }) => id)
        .includes(this.group.id)
    );
  }

  /**
   * New members, if on a different server,
   * can take a while to refresh the group and fetch all private data
   */
  get isCurrentActorARecentMember(): boolean {
    return (
      this.groupMember !== undefined &&
      this.groupMember.role === MemberRole.MEMBER &&
      addMinutes(new Date(`${this.groupMember.updatedAt}Z`), 10) > new Date()
    );
  }

  get isCurrentActorOnADifferentDomainThanGroup(): boolean {
    return this.group.domain !== null;
  }

  get members(): IMember[] {
    return this.group.members.elements.filter(
      (member) =>
        ![
          MemberRole.INVITED,
          MemberRole.REJECTED,
          MemberRole.NOT_APPROVED,
        ].includes(member.role)
    );
  }

  get physicalAddress(): Address | null {
    if (!this.group.physicalAddress) return null;
    return new Address(this.group.physicalAddress);
  }

  get ableToReport(): boolean {
    return (
      this.config &&
      (this.currentActor.id !== undefined ||
        this.config.anonymous.reports.allowed)
    );
  }

  get organizedEvents(): Paginate<IEvent> {
    return {
      total: this.group.organizedEvents.total,
      elements: this.group.organizedEvents.elements.filter((event: IEvent) => {
        if (this.previewPublic) {
          return !event.draft; // TODO when events get visibility access add visibility constraint like below for posts
        }
        return true;
      }),
    };
  }

  get posts(): Paginate<IPost> {
    return {
      total: this.group.posts.total,
      elements: this.group.posts.elements.filter((post: IPost) => {
        if (this.previewPublic) {
          return !(post.draft || post.visibility == PostVisibility.PRIVATE);
        }
        return true;
      }),
    };
  }
}
</script>
<style lang="scss" scoped>
@import "~bulma/sass/utilities/mixins.sass";
div.container {
  margin-bottom: 3rem;

  .header,
  .public-container {
    display: flex;
    flex-direction: column;
  }

  .header {
    background: $white;
    padding-top: 1rem;
  }

  .header .breadcrumb {
    margin-bottom: 0.5rem;
    margin-left: 0.5rem;
  }

  .block-container {
    display: flex;
    flex-wrap: wrap;
    margin-top: 15px;

    &.presentation {
      border: 2px solid $purple-2;
      padding: 0 0 10px;
      position: relative;
      flex-direction: column;

      h1 {
        color: $purple-1;
        font-size: 2rem;
        font-weight: 500;
      }

      .button.is-outlined {
        border-color: $purple-2;
      }

      & > *:not(img) {
        position: relative;
        z-index: 2;
      }

      & > .banner-container {
        display: flex;
        justify-content: center;
        height: 30vh;
        ::v-deep img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          object-position: 50% 50%;
        }
      }
    }

    div.address {
      flex: 1;
      text-align: right;
      justify-content: flex-end;
      display: flex;

      .map-show-button {
        cursor: pointer;
      }

      p.buttons {
        margin-top: 1rem;
        justify-content: end;
        align-content: space-between;

        & > span {
          margin-right: 0.5rem;
        }
      }

      address {
        font-style: normal;

        span.addressDescription {
          text-overflow: ellipsis;
          white-space: nowrap;
          flex: 1 0 auto;
          min-width: 100%;
          max-width: 4rem;
          overflow: hidden;
        }

        :not(.addressDescription) {
          color: rgba(46, 62, 72, 0.6);
          flex: 1;
          min-width: 100%;
        }
      }
    }

    .block-column {
      flex: 1;
      margin: 0;
      max-width: 576px;

      @include desktop {
        margin: 0 0.5rem;

        &:first-child {
          margin-left: 0;
        }
        &:last-child {
          margin-right: 0;
        }
      }

      section {
        background: $white;

        .posts-wrapper {
          padding-bottom: 1rem;
        }

        .organized-events-wrapper {
          display: flex;
          flex-wrap: wrap;

          .organized-event {
            margin: 0.25rem 0;
          }
        }

        &.presentation {
          .media-left {
            span.icon.is-large {
              height: 5rem;
              width: 5rem;

              ::v-deep i.mdi.mdi-account-group.mdi-48px:before {
                font-size: 100px;
              }
            }
          }

          .media-content {
            h2 {
              color: #3c376e;
              font-family: "Liberation Sans", "Helvetica Neue", Roboto,
                Helvetica, Arial, serif;
              font-size: 1.5rem;
              font-weight: 700;
            }
          }
        }
      }
    }

    .header {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      flex-direction: column;
      flex: 1;
      margin: 0;
      align-items: center;

      .avatar-container {
        display: flex;
        align-self: center;
        height: 0;
        margin-top: 16px;
        align-items: flex-end;

        ::v-deep .icon {
          border-radius: 290486px;
          border: 1px solid #cdcaea;
          background: white;
          height: 5rem;
          width: 5rem;
          i::before {
            font-size: 60px;
          }
        }

        figure {
          position: relative;

          img {
            position: absolute;
            background: #fff;
          }
        }
      }

      .title-container {
        flex: 1;
        display: flex;
        flex-direction: column;
        text-align: center;

        h1 {
          font-size: 32px;
          line-height: 38px;
        }
      }

      .group-metadata {
        display: flex;
        flex-direction: row;
        flex-wrap: wrap;
        justify-content: center;

        & > .buttons {
          justify-content: center;

          ::v-deep .b-tooltip {
            padding-right: 0.5em;
          }
        }

        .members {
          display: flex;
          flex-direction: column;
          min-width: 300px;
          align-items: center;

          div {
            display: flex;
          }

          figure:not(:first-child) {
            margin-left: -10px;
          }
        }
      }
    }
  }

  .public-container {
    display: flex;
    flex-wrap: wrap;
    flex-direction: row-reverse;
    padding: 0;
    margin-top: 1rem;

    .group-metadata {
      min-width: 20rem;
      flex: 1;
      padding-left: 1rem;
      @include mobile {
        padding-left: 0;
      }

      .sticky {
        position: sticky;
        background: white;
        top: 50px;
        padding: 1rem;
      }
    }
    .main-content {
      min-width: 20rem;
      flex: 2;
      background: white;

      @include desktop {
        padding: 10px;
      }

      @include mobile {
        margin-top: 1rem;
      }

      h2 {
        margin: 0 auto 10px;
      }
    }

    section {
      margin-top: 0;

      .posts-wrapper {
        margin-bottom: 1rem;
      }
    }
  }

  .menu-dropdown {
    ::v-deep .dropdown-item,
    ::v-deep .has-link a {
      padding-right: 1rem;
    }
  }
}
</style>
