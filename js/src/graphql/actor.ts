import gql from "graphql-tag";

export const FETCH_PERSON = gql`
  query($username: String!) {
    fetchPerson(preferredUsername: $username) {
      id
      url
      name
      domain
      summary
      preferredUsername
      suspended
      avatar {
        name
        url
      }
      banner {
        url
      }
      feedTokens {
        token
      }
      organizedEvents {
        total
        elements {
          uuid
          title
          beginsOn
        }
      }
    }
  }
`;

export const GET_PERSON = gql`
  query(
    $actorId: ID!
    $organizedEventsPage: Int
    $organizedEventsLimit: Int
    $participationPage: Int
    $participationLimit: Int
  ) {
    person(id: $actorId) {
      id
      url
      name
      domain
      summary
      preferredUsername
      suspended
      avatar {
        name
        url
      }
      banner {
        url
      }
      feedTokens {
        token
      }
      organizedEvents(page: $organizedEventsPage, limit: $organizedEventsLimit) {
        total
        elements {
          id
          uuid
          title
          beginsOn
        }
      }
      participations(page: $participationPage, limit: $participationLimit) {
        total
        elements {
          id
          event {
            id
            uuid
            title
            beginsOn
          }
        }
      }
      user {
        id
        email
      }
    }
  }
`;

export const LIST_PROFILES = gql`
  query ListProfiles(
    $preferredUsername: String
    $name: String
    $domain: String
    $local: Boolean
    $suspended: Boolean
    $page: Int
    $limit: Int
  ) {
    persons(
      preferredUsername: $preferredUsername
      name: $name
      domain: $domain
      local: $local
      suspended: $suspended
      page: $page
      limit: $limit
    ) {
      total
      elements {
        id
        preferredUsername
        domain
        name
        avatar {
          url
        }
      }
    }
  }
`;

export const LOGGED_PERSON = gql`
  query {
    loggedPerson {
      id
      avatar {
        url
      }
      preferredUsername
    }
  }
`;

export const UPDATE_DEFAULT_ACTOR = gql`
  mutation ChangeDefaultActor($preferredUsername: String!) {
    changeDefaultActor(preferredUsername: $preferredUsername) {
      id
      defaultActor {
        id
      }
    }
  }
`;

export const CURRENT_ACTOR_CLIENT = gql`
  query currentActor {
    currentActor @client {
      id
      avatar {
        url
      }
      preferredUsername
      name
    }
  }
`;

export const UPDATE_CURRENT_ACTOR_CLIENT = gql`
  mutation UpdateCurrentActor(
    $id: String!
    $avatar: String
    $preferredUsername: String!
    $name: String!
  ) {
    updateCurrentActor(id: $id, avatar: $avatar, preferredUsername: $preferredUsername, name: $name)
    @client
  }
`;

export const LOGGED_USER_PARTICIPATIONS = gql`
  query LoggedUserParticipations(
    $afterDateTime: DateTime
    $beforeDateTime: DateTime
    $page: Int
    $limit: Int
  ) {
    loggedUser {
      participations(
        afterDatetime: $afterDateTime
        beforeDatetime: $beforeDateTime
        page: $page
        limit: $limit
      ) {
        total
        elements {
          event {
            id
            uuid
            title
            picture {
              id
              url
              alt
            }
            beginsOn
            visibility
            organizerActor {
              id
              preferredUsername
              name
              domain
              summary
              avatar {
                url
              }
            }
            participantStats {
              going
              notApproved
              participant
            }
            options {
              maximumAttendeeCapacity
              remainingAttendeeCapacity
            }
          }
          id
          role
          actor {
            id
            preferredUsername
            name
            domain
            summary
            avatar {
              url
            }
          }
        }
      }
    }
  }
`;

export const LOGGED_USER_DRAFTS = gql`
  query LoggedUserDrafts($page: Int, $limit: Int) {
    loggedUser {
      drafts(page: $page, limit: $limit) {
        id
        uuid
        title
        picture {
          id
          url
          alt
        }
        beginsOn
        visibility
        organizerActor {
          id
          preferredUsername
          name
          domain
          avatar {
            url
          }
        }
        participantStats {
          going
          notApproved
        }
        options {
          maximumAttendeeCapacity
          remainingAttendeeCapacity
        }
      }
    }
  }
`;

export const LOGGED_USER_MEMBERSHIPS = gql`
  query LoggedUserMemberships($page: Int, $limit: Int) {
    loggedUser {
      memberships(page: $page, limit: $limit) {
        total
        elements {
          id
          role
          parent {
            id
            preferredUsername
            domain
            name
            avatar {
              url
            }
            organizedEvents {
              elements {
                id
                title
                picture {
                  url
                }
              }
              total
            }
          }
          invitedBy {
            id
            preferredUsername
            domain
            name
            avatar {
              url
            }
          }
        }
      }
    }
  }
`;

export const IDENTITIES = gql`
  query {
    identities {
      id
      avatar {
        url
      }
      preferredUsername
      name
    }
  }
`;

export const PERSON_MEMBERSHIPS = gql`
  query PersonMemberships($id: ID!) {
    person(id: $id) {
      id
      memberships {
        total
        elements {
          id
          role
          parent {
            id
            preferredUsername
            name
            domain
            avatar {
              url
            }
          }
          invitedBy {
            id
            preferredUsername
            name
          }
          insertedAt
          updatedAt
        }
      }
    }
  }
`;

export const CREATE_PERSON = gql`
  mutation CreatePerson(
    $preferredUsername: String!
    $name: String!
    $summary: String
    $avatar: PictureInput
  ) {
    createPerson(
      preferredUsername: $preferredUsername
      name: $name
      summary: $summary
      avatar: $avatar
    ) {
      id
      preferredUsername
      name
      summary
      avatar {
        url
      }
    }
  }
`;

export const UPDATE_PERSON = gql`
  mutation UpdatePerson($id: ID!, $name: String, $summary: String, $avatar: PictureInput) {
    updatePerson(id: $id, name: $name, summary: $summary, avatar: $avatar) {
      id
      preferredUsername
      name
      summary
      avatar {
        url
      }
    }
  }
`;

export const DELETE_PERSON = gql`
  mutation DeletePerson($id: ID!) {
    deletePerson(id: $id) {
      preferredUsername
    }
  }
`;

/**
 * This one is used only to register the first account.
 * Prefer CREATE_PERSON when creating another identity
 */
export const REGISTER_PERSON = gql`
  mutation($preferredUsername: String!, $name: String!, $summary: String!, $email: String!) {
    registerPerson(
      preferredUsername: $preferredUsername
      name: $name
      summary: $summary
      email: $email
    ) {
      id
      preferredUsername
      name
      summary
      avatar {
        url
      }
    }
  }
`;

export const SUSPEND_PROFILE = gql`
  mutation SuspendProfile($id: ID!) {
    suspendProfile(id: $id) {
      id
    }
  }
`;

export const UNSUSPEND_PROFILE = gql`
  mutation UnSuspendProfile($id: ID!) {
    unsuspendProfile(id: $id) {
      id
    }
  }
`;
