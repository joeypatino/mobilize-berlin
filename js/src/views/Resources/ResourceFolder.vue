<template>
  <div class="container section" v-if="resource">
    <nav class="breadcrumb" aria-label="breadcrumbs">
      <ul>
        <li>
          <router-link
            :to="{
              name: RouteName.GROUP,
              params: { preferredUsername: usernameWithDomain(resource.actor) },
            }"
            >{{ resource.actor.preferredUsername }}</router-link
          >
        </li>
        <li>
          <router-link
            :to="{
              name: RouteName.RESOURCE_FOLDER_ROOT,
              params: { preferredUsername: usernameWithDomain(resource.actor) },
            }"
            >{{ $t("Resources") }}</router-link
          >
        </li>
        <li
          v-if="resource.path !== '/'"
          :class="{ 'is-active': index + 1 === ResourceMixin.resourcePathArray(resource).length }"
          v-for="(pathFragment, index) in ResourceMixin.resourcePathArray(resource)"
          :key="pathFragment"
        >
          <router-link
            :to="{
              name: RouteName.RESOURCE_FOLDER,
              params: {
                path: ResourceMixin.resourcePathArray(resource).slice(0, index + 1),
                preferredUsername: resource.actor.preferredUsername,
              },
            }"
            >{{ pathFragment }}</router-link
          >
        </li>
        <li>
          <b-dropdown aria-role="list">
            <b-button class="button is-primary" slot="trigger">+</b-button>

            <b-dropdown-item aria-role="listitem" @click="createFolderModal">
              <b-icon icon="folder" />
              {{ $t("New folder") }}
            </b-dropdown-item>
            <b-dropdown-item aria-role="listitem" @click="createLinkResourceModal = true">
              <b-icon icon="link" />
              {{ $t("New link") }}
            </b-dropdown-item>
            <hr class="dropdown-divider" v-if="config.resourceProviders.length" />
            <b-dropdown-item
              aria-role="listitem"
              v-for="resourceProvider in config.resourceProviders"
              :key="resourceProvider.software"
              @click="createResourceFromProvider(resourceProvider)"
            >
              <b-icon :icon="mapServiceTypeToIcon[resourceProvider.software]" />
              {{ createSentenceForType(resourceProvider.software) }}
            </b-dropdown-item>
          </b-dropdown>
        </li>
      </ul>
    </nav>
    <section>
      <div class="list-header">
        <div class="list-header-right">
          <b-checkbox v-model="checkedAll" />
          <div class="actions" v-if="validCheckedResources.length > 0">
            <small>
              {{
                $tc("No resources selected", validCheckedResources.length, {
                  count: validCheckedResources.length,
                })
              }}
            </small>
            <b-button
              type="is-danger"
              icon-right="delete"
              size="is-small"
              @click="deleteMultipleResources"
              >{{ $t("Delete") }}</b-button
            >
          </div>
        </div>
      </div>
      <draggable v-model="resource.children.elements" :sort="false" :group="groupObject">
        <transition-group>
          <div v-for="localResource in resource.children.elements" :key="localResource.id">
            <div class="resource-item">
              <div
                class="resource-checkbox"
                :class="{ checked: checkedResources[localResource.id] }"
              >
                <b-checkbox v-model="checkedResources[localResource.id]" />
              </div>
              <resource-item
                :resource="localResource"
                v-if="localResource.type !== 'folder'"
                @delete="deleteResource"
                @rename="handleRename"
              />
              <folder-item
                :resource="localResource"
                :group="resource.actor"
                @delete="deleteResource"
                @rename="handleRename"
                v-else
              />
            </div>
          </div>
        </transition-group>
      </draggable>
    </section>
    <b-modal :active.sync="renameModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <form @submit.prevent="renameResource">
            <b-field :label="$t('Title')">
              <b-input aria-required="true" v-model="updatedResource.title" />
            </b-field>

            <b-button native-type="submit">{{ $t("Rename resource") }}</b-button>
          </form>
        </section>
      </div>
    </b-modal>
    <b-modal :active.sync="createResourceModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <form @submit.prevent="createResource">
            <b-field :label="$t('Title')">
              <b-input aria-required="true" v-model="newResource.title" />
            </b-field>

            <b-button native-type="submit">{{ createResourceButtonLabel }}</b-button>
          </form>
        </section>
      </div>
    </b-modal>
    <b-modal :active.sync="createLinkResourceModal" has-modal-card>
      <div class="modal-card">
        <section class="modal-card-body">
          <form @submit.prevent="createResource">
            <b-field :label="$t('URL')">
              <b-input
                type="url"
                required
                v-model="newResource.resourceUrl"
                @blur="previewResource"
              />
            </b-field>

            <div class="new-resource-preview" v-if="newResource.title">
              <resource-item :resource="newResource" />
            </div>

            <b-field :label="$t('Title')">
              <b-input aria-required="true" v-model="newResource.title" />
            </b-field>

            <b-field :label="$t('Text')">
              <b-input type="textarea" v-model="newResource.summary" />
            </b-field>

            <b-button native-type="submit">{{ $t("Create resource") }}</b-button>
          </form>
        </section>
      </div>
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Mixins, Prop, Watch } from "vue-property-decorator";
import ResourceItem from "@/components/Resource/ResourceItem.vue";
import FolderItem from "@/components/Resource/FolderItem.vue";
import Draggable from "vuedraggable";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";
import { IActor, usernameWithDomain } from "../../types/actor";
import RouteName from "../../router/name";
import { IResource, mapServiceTypeToIcon, IProvider } from "../../types/resource";
import {
  CREATE_RESOURCE,
  DELETE_RESOURCE,
  PREVIEW_RESOURCE_LINK,
  GET_RESOURCE,
  UPDATE_RESOURCE,
} from "../../graphql/resources";
import { CONFIG } from "../../graphql/config";
import { IConfig } from "../../types/config.model";
import ResourceMixin from "../../mixins/resource";

@Component({
  components: { FolderItem, ResourceItem, Draggable },
  apollo: {
    resource: {
      query: GET_RESOURCE,
      variables() {
        let path = Array.isArray(this.$route.params.path)
          ? this.$route.params.path.join("/")
          : this.$route.params.path || this.path;
        path = path[0] !== "/" ? `/${path}` : path;
        return {
          path,
          username: this.$route.params.preferredUsername,
        };
      },
    },
    config: CONFIG,
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class Resources extends Mixins(ResourceMixin) {
  @Prop({ required: true }) path!: string;

  resource!: IResource;

  config!: IConfig;

  currentActor!: IActor;

  RouteName = RouteName;

  ResourceMixin = ResourceMixin;

  usernameWithDomain = usernameWithDomain;

  newResource: IResource = {
    title: "",
    summary: "",
    resourceUrl: "",
    children: { elements: [], total: 0 },
    metadata: {},
    type: "link",
  };

  updatedResource: IResource = {
    title: "",
    resourceUrl: "",
    metadata: {},
    children: { elements: [], total: 0 },
    path: undefined,
  };

  checkedResources: { [key: string]: boolean } = {};

  validCheckedResources: string[] = [];

  checkedAll = false;

  createResourceModal = false;

  createLinkResourceModal = false;

  renameModal = false;

  groupObject: object = {
    name: "resources",
    pull: "clone",
    put: true,
  };

  mapServiceTypeToIcon = mapServiceTypeToIcon;

  async createResource() {
    if (!this.resource.actor) return;
    try {
      const { data } = await this.$apollo.mutate({
        mutation: CREATE_RESOURCE,
        variables: {
          title: this.newResource.title,
          summary: this.newResource.summary,
          actorId: this.resource.actor.id,
          resourceUrl: this.newResource.resourceUrl,
          parentId:
            this.resource.id && this.resource.id.startsWith("root_") ? null : this.resource.id,
          type: this.newResource.type,
        },
        update: (store, { data: { createResource } }) => {
          if (createResource == null) return;
          if (!this.resource.actor) return;
          const cachedData = store.readQuery<{ resource: IResource }>({
            query: GET_RESOURCE,
            variables: {
              path: this.resource.path,
              username: this.resource.actor.preferredUsername,
            },
          });
          if (cachedData == null) return;
          const { resource } = cachedData;
          if (resource == null) {
            console.error("Cannot update resource cache, because of null value.");
            return;
          }
          const newResource: IResource = createResource;
          resource.children.elements = resource.children.elements.concat([newResource]);

          store.writeQuery({
            query: GET_RESOURCE,
            variables: {
              path: this.resource.path,
              username: this.resource.actor.preferredUsername,
            },
            data: { resource },
          });
        },
      });
      this.createLinkResourceModal = false;
      this.createResourceModal = false;
      this.newResource.title = "";
      this.newResource.summary = "";
      this.newResource.resourceUrl = "";
    } catch (err) {
      console.error(err);
    }
  }

  async previewResource() {
    if (this.newResource.resourceUrl === "") return;
    const { data } = await this.$apollo.mutate({
      mutation: PREVIEW_RESOURCE_LINK,
      variables: {
        resourceUrl: this.newResource.resourceUrl,
      },
    });
    this.newResource.title = data.previewResourceLink.title;
    this.newResource.summary = data.previewResourceLink.description;
    this.newResource.metadata = data.previewResourceLink;
    this.newResource.type = "link";
  }

  createSentenceForType(type: string) {
    switch (type) {
      case "pad":
        return this.$t("Create a pad");
      case "calc":
        return this.$t("Create a calc");
      case "visio":
        return this.$t("Create a visioconference");
    }
  }

  createFolderModal() {
    this.newResource.type = "folder";
    this.createResourceModal = true;
  }

  createResourceFromProvider(provider: IProvider) {
    console.log(provider);
    this.newResource.resourceUrl = this.generateFullResourceUrl(provider);
    this.newResource.type = provider.software;
    this.createResourceModal = true;
  }

  generateFullResourceUrl(provider: IProvider): string {
    const randomString = [...Array(10)]
      .map(() => Math.random().toString(36)[3])
      .join("")
      .replace(/(.|$)/g, (c) => c[!Math.round(Math.random()) ? "toString" : "toLowerCase"]());
    switch (provider.type) {
      case "ethercalc":
      case "etherpad":
      case "jitsi":
      default:
        return `${provider.endpoint}${randomString}`;
    }
  }

  get createResourceButtonLabel() {
    if (!this.newResource.type) return;
    return this.createSentenceForType(this.newResource.type);
  }

  @Watch("checkedAll")
  watchCheckedAll() {
    this.resource.children.elements.forEach(({ id }) => {
      if (!id) return;
      this.checkedResources[id] = this.checkedAll;
    });
  }

  @Watch("checkedResources", { deep: true })
  watchValidCheckedResources(): string[] {
    const validCheckedResources: string[] = [];
    for (const [key, value] of Object.entries(this.checkedResources)) {
      if (value) {
        validCheckedResources.push(key);
      }
    }
    return (this.validCheckedResources = validCheckedResources);
  }

  async deleteMultipleResources() {
    for (const resourceID of this.validCheckedResources) {
      await this.deleteResource(resourceID);
    }
  }

  async deleteResource(resourceID: string) {
    try {
      await this.$apollo.mutate({
        mutation: DELETE_RESOURCE,
        variables: {
          id: resourceID,
        },
        update: (store, { data: { deleteResource } }) => {
          if (deleteResource == null) return;
          if (!this.resource.actor) return;
          const cachedData = store.readQuery<{ resource: IResource }>({
            query: GET_RESOURCE,
            variables: {
              path: this.resource.path,
              username: this.resource.actor.preferredUsername,
            },
          });
          if (cachedData == null) return;
          const { resource } = cachedData;
          if (resource == null) {
            console.error("Cannot update resource cache, because of null value.");
            return;
          }
          const oldResource: IResource = deleteResource;

          resource.children.elements = resource.children.elements.filter(
            (resource) => resource.id !== oldResource.id
          );

          store.writeQuery({
            query: GET_RESOURCE,
            variables: {
              path: this.resource.path,
              username: this.resource.actor.preferredUsername,
            },
            data: { resource },
          });
        },
      });
      this.validCheckedResources = this.validCheckedResources.filter((id) => id !== resourceID);
      delete this.checkedResources[resourceID];
    } catch (e) {
      console.error(e);
    }
  }

  handleRename(resource: IResource) {
    this.renameModal = true;
    this.updatedResource = resource;
  }

  async renameResource() {
    await this.updateResource(this.updatedResource);
  }

  async updateResource(resource: IResource) {
    try {
      if (!resource.parent) return;
      await this.$apollo.mutate<{ updateResource: IResource }>({
        mutation: UPDATE_RESOURCE,
        variables: {
          id: resource.id,
          title: resource.title,
          parentId: resource.parent.id,
          path: resource.path,
        },
      });
    } catch (e) {
      console.error(e);
    }
  }
}
</script>
<style lang="scss" scoped>
nav.breadcrumb ul {
  align-items: center;

  li:last-child .dropdown {
    margin-left: 5px;

    a {
      justify-content: left;
      color: inherit;
      padding: 0.375rem 1rem;
    }
  }
}

.list-header {
  display: flex;
  justify-content: space-between;

  .list-header-right {
    display: flex;
    align-items: center;

    .actions {
      margin-right: 5px;

      & > * {
        margin-left: 5px;
      }
    }
  }
}

.resource-item,
.new-resource-preview {
  display: flex;
  font-size: 14px;
  border: 1px solid #c0cdd9;
  border-radius: 4px;
  color: #444b5d;
  margin-top: 14px;

  .resource-checkbox {
    align-self: center;
    padding: 0 3px 0 10px;
    opacity: 0.3;
  }

  &:hover .resource-checkbox,
  .resource-checkbox.checked {
    opacity: 1;
  }
}
</style>