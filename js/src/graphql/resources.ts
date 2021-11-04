import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";

export const RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT = gql`
  fragment ResourceMetadataBasicFields on ResourceMetadata {
    imageRemoteUrl
    height
    width
    type
    faviconUrl
  }
`;

export const GET_RESOURCE = gql`
  query GetResource(
    $path: String!
    $username: String!
    $page: Int
    $limit: Int
  ) {
    resource(path: $path, username: $username) {
      id
      title
      summary
      url
      path
      type
      metadata {
        ...ResourceMetadataBasicFields
        authorName
        authorUrl
        providerName
        providerUrl
        html
      }
      parent {
        id
        path
        type
      }
      actor {
        ...ActorFragment
      }
      children(page: $page, limit: $limit) {
        total
        elements {
          id
          title
          summary
          url
          type
          path
          resourceUrl
          parent {
            id
            path
            type
          }
          publishedAt
          updatedAt
          insertedAt
          metadata {
            ...ResourceMetadataBasicFields
          }
        }
      }
    }
  }
  ${ACTOR_FRAGMENT}
  ${RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT}
`;

export const CREATE_RESOURCE = gql`
  mutation CreateResource(
    $title: String!
    $parentId: ID
    $summary: String
    $actorId: ID!
    $resourceUrl: String
    $type: String
  ) {
    createResource(
      title: $title
      parentId: $parentId
      summary: $summary
      actorId: $actorId
      resourceUrl: $resourceUrl
      type: $type
    ) {
      id
      title
      summary
      url
      resourceUrl
      updatedAt
      path
      type
      metadata {
        ...ResourceMetadataBasicFields
        authorName
        authorUrl
        providerName
        providerUrl
        html
      }
    }
  }
  ${RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT}
`;

export const UPDATE_RESOURCE = gql`
  mutation UpdateResource(
    $id: ID!
    $title: String
    $summary: String
    $parentId: ID
    $resourceUrl: String
  ) {
    updateResource(
      id: $id
      title: $title
      parentId: $parentId
      summary: $summary
      resourceUrl: $resourceUrl
    ) {
      id
      title
      summary
      url
      path
      type
      resourceUrl
      parent {
        id
        path
      }
    }
  }
`;

export const DELETE_RESOURCE = gql`
  mutation DeleteResource($id: ID!) {
    deleteResource(id: $id) {
      id
    }
  }
`;

export const PREVIEW_RESOURCE_LINK = gql`
  mutation PreviewResourceLink($resourceUrl: String!) {
    previewResourceLink(resourceUrl: $resourceUrl) {
      title
      description
      ...ResourceMetadataBasicFields
      authorName
      authorUrl
      providerName
      providerUrl
      html
    }
  }
  ${RESOURCE_METADATA_BASIC_FIELDS_FRAGMENT}
`;
