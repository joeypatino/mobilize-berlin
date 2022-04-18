import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";
import { TAG_FRAGMENT } from "./tags";

export const POST_FRAGMENT = gql`
  fragment PostFragment on Post {
    id
    title
    slug
    url
    body
    draft
    author {
      ...ActorFragment
    }
    attributedTo {
      ...ActorFragment
    }
    insertedAt
    updatedAt
    publishAt
    draft
    visibility
    language
    tags {
      ...TagFragment
    }
    picture {
      id
      url
      name
      metadata {
        height
        width
        blurhash
      }
    }
  }
  ${TAG_FRAGMENT}
  ${ACTOR_FRAGMENT}
`;

export const POST_BASIC_FIELDS = gql`
  fragment PostBasicFields on Post {
    id
    title
    slug
    url
    author {
      ...ActorFragment
    }
    attributedTo {
      ...ActorFragment
    }
    insertedAt
    updatedAt
    publishAt
    draft
    visibility
    language
    picture {
      id
      url
      name
    }
    tags {
      ...TagFragment
    }
  }
  ${ACTOR_FRAGMENT}
  ${TAG_FRAGMENT}
`;

export const FETCH_GROUP_POSTS = gql`
  query GroupPosts($preferredUsername: String!, $page: Int, $limit: Int) {
    group(preferredUsername: $preferredUsername) {
      ...ActorFragment
      posts(page: $page, limit: $limit) {
        total
        elements {
          ...PostBasicFields
        }
      }
    }
  }
  ${POST_BASIC_FIELDS}
`;

export const FETCH_POST = gql`
  query Post($slug: String!) {
    post(slug: $slug) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const CREATE_POST = gql`
  mutation CreatePost(
    $title: String!
    $body: String!
    $attributedToId: ID!
    $visibility: PostVisibility
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
  ) {
    createPost(
      title: $title
      body: $body
      attributedToId: $attributedToId
      visibility: $visibility
      draft: $draft
      tags: $tags
      picture: $picture
    ) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const UPDATE_POST = gql`
  mutation UpdatePost(
    $id: ID!
    $title: String
    $body: String
    $attributedToId: ID
    $visibility: PostVisibility
    $draft: Boolean
    $tags: [String]
    $picture: MediaInput
  ) {
    updatePost(
      id: $id
      title: $title
      body: $body
      attributedToId: $attributedToId
      visibility: $visibility
      draft: $draft
      tags: $tags
      picture: $picture
    ) {
      ...PostFragment
    }
  }
  ${POST_FRAGMENT}
`;

export const DELETE_POST = gql`
  mutation DeletePost($id: ID!) {
    deletePost(id: $id) {
      id
    }
  }
`;
