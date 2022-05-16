import gql from "graphql-tag";
import { ACTOR_FRAGMENT } from "./actor";

export const DASHBOARD = gql`
  query {
    dashboard {
      lastPublicEventPublished {
        id
        uuid
        title
        picture {
          id
          alt
          url
        }
      }
      lastGroupCreated {
        ...ActorFragment
      }
      numberOfUsers
      numberOfEvents
      numberOfComments
      numberOfReports
      numberOfGroups
      numberOfFollowers
      numberOfFollowings
      numberOfConfirmedParticipationsToLocalEvents
    }
  }
  ${ACTOR_FRAGMENT}
`;

export const RELAY_FRAGMENT = gql`
  fragment relayFragment on Follower {
    id
    actor {
      ...ActorFragment
    }
    targetActor {
      ...ActorFragment
    }
    approved
    insertedAt
    updatedAt
  }
  ${ACTOR_FRAGMENT}
`;

export const RELAY_FOLLOWERS = gql`
  query relayFollowers($page: Int, $limit: Int) {
    relayFollowers(page: $page, limit: $limit) {
      elements {
        ...relayFragment
      }
      total
    }
  }
  ${RELAY_FRAGMENT}
`;

export const RELAY_FOLLOWINGS = gql`
  query relayFollowings($page: Int, $limit: Int) {
    relayFollowings(page: $page, limit: $limit) {
      elements {
        ...relayFragment
      }
      total
    }
  }
  ${RELAY_FRAGMENT}
`;

export const INSTANCE_FRAGMENT = gql`
  fragment InstanceFragment on Instance {
    domain
    hasRelay
    relayAddress
    followerStatus
    followedStatus
    eventCount
    personCount
    groupCount
    followersCount
    followingsCount
    reportsCount
    mediaSize
  }
`;

export const INSTANCE = gql`
  query instance($domain: ID!) {
    instance(domain: $domain) {
      ...InstanceFragment
    }
  }
  ${INSTANCE_FRAGMENT}
`;

export const INSTANCES = gql`
  query Instances(
    $page: Int
    $limit: Int
    $orderBy: InstancesSortFields
    $direction: String
    $filterDomain: String
    $filterFollowStatus: InstanceFilterFollowStatus
    $filterSuspendStatus: InstanceFilterSuspendStatus
  ) {
    instances(
      page: $page
      limit: $limit
      orderBy: $orderBy
      direction: $direction
      filterDomain: $filterDomain
      filterFollowStatus: $filterFollowStatus
      filterSuspendStatus: $filterSuspendStatus
    ) {
      total
      elements {
        ...InstanceFragment
      }
    }
  }
  ${INSTANCE_FRAGMENT}
`;
export const ADD_INSTANCE = gql`
  mutation addInstance($domain: String!) {
    addInstance(domain: $domain) {
      ...InstanceFragment
    }
  }
  ${INSTANCE_FRAGMENT}
`;

export const REMOVE_RELAY = gql`
  mutation removeRelay($address: String!) {
    removeRelay(address: $address) {
      ...relayFragment
    }
  }
  ${RELAY_FRAGMENT}
`;

export const ACCEPT_RELAY = gql`
  mutation acceptRelay($address: String!) {
    acceptRelay(address: $address) {
      ...relayFragment
    }
  }
  ${RELAY_FRAGMENT}
`;

export const REJECT_RELAY = gql`
  mutation rejectRelay($address: String!) {
    rejectRelay(address: $address) {
      ...relayFragment
    }
  }
  ${RELAY_FRAGMENT}
`;

export const LANGUAGES = gql`
  query {
    languages {
      code
      name
    }
  }
`;

export const LANGUAGES_CODES = gql`
  query LanguagesCodes($codes: [String!]) {
    languages(codes: $codes) {
      code
      name
    }
  }
`;

export const ADMIN_SETTINGS_FRAGMENT = gql`
  fragment adminSettingsFragment on AdminSettings {
    instanceName
    instanceDescription
    instanceLongDescription
    instanceSlogan
    contact
    instanceTerms
    instanceTermsType
    instanceTermsUrl
    instancePrivacyPolicy
    instancePrivacyPolicyType
    instancePrivacyPolicyUrl
    instanceRules
    registrationsOpen
    instanceLanguages
  }
`;

export const ADMIN_SETTINGS = gql`
  query {
    adminSettings {
      ...adminSettingsFragment
    }
  }
  ${ADMIN_SETTINGS_FRAGMENT}
`;

export const SAVE_ADMIN_SETTINGS = gql`
  mutation SaveAdminSettings(
    $instanceName: String
    $instanceDescription: String
    $instanceLongDescription: String
    $instanceSlogan: String
    $contact: String
    $instanceTerms: String
    $instanceTermsType: InstanceTermsType
    $instanceTermsUrl: String
    $instancePrivacyPolicy: String
    $instancePrivacyPolicyType: InstancePrivacyType
    $instancePrivacyPolicyUrl: String
    $instanceRules: String
    $registrationsOpen: Boolean
    $instanceLanguages: [String]
  ) {
    saveAdminSettings(
      instanceName: $instanceName
      instanceDescription: $instanceDescription
      instanceLongDescription: $instanceLongDescription
      instanceSlogan: $instanceSlogan
      contact: $contact
      instanceTerms: $instanceTerms
      instanceTermsType: $instanceTermsType
      instanceTermsUrl: $instanceTermsUrl
      instancePrivacyPolicy: $instancePrivacyPolicy
      instancePrivacyPolicyType: $instancePrivacyPolicyType
      instancePrivacyPolicyUrl: $instancePrivacyPolicyUrl
      instanceRules: $instanceRules
      registrationsOpen: $registrationsOpen
      instanceLanguages: $instanceLanguages
    ) {
      ...adminSettingsFragment
    }
  }
  ${ADMIN_SETTINGS_FRAGMENT}
`;

export const ADMIN_UPDATE_USER = gql`
  mutation AdminUpdateUser(
    $id: ID!
    $email: String
    $role: UserRole
    $confirmed: Boolean
    $notify: Boolean
  ) {
    adminUpdateUser(
      id: $id
      email: $email
      role: $role
      confirmed: $confirmed
      notify: $notify
    ) {
      id
      email
      role
      confirmedAt
    }
  }
`;
