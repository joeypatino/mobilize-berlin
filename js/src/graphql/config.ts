import gql from "graphql-tag";

export const CONFIG = gql`
  query FullConfig {
    config {
      name
      description
      slogan
      registrationsOpen
      registrationsAllowlist
      demoMode
      countryCode
      languages
      eventCategories {
        id
        label
      }
      anonymous {
        participation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
        eventCreation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
        reports {
          allowed
        }
        actorId
      }
      location {
        latitude
        longitude
        # accuracyRadius
      }
      maps {
        tiles {
          endpoint
          attribution
        }
        routing {
          type
        }
      }
      geocoding {
        provider
        autocomplete
      }
      resourceProviders {
        type
        endpoint
        software
      }
      features {
        groups
        eventCreation
      }
      restrictions {
        onlyAdminCanCreateGroups
        onlyGroupsCanCreateEvents
      }
      auth {
        ldap
        oauthProviders {
          id
          label
        }
      }
      uploadLimits {
        default
        avatar
        banner
      }
      instanceFeeds {
        enabled
      }
      webPush {
        enabled
        publicKey
      }
      analytics {
        id
        enabled
        configuration {
          key
          value
          type
        }
      }
    }
  }
`;

export const CONFIG_EDIT_EVENT = gql`
  query EditEventConfig {
    config {
      timezones
      features {
        groups
      }
      eventCategories {
        id
        label
      }
      anonymous {
        participation {
          allowed
          validation {
            email {
              enabled
              confirmationRequired
            }
            captcha {
              enabled
            }
          }
        }
      }
    }
  }
`;

export const TERMS = gql`
  query Terms($locale: String) {
    config {
      terms(locale: $locale) {
        type
        url
        bodyHtml
      }
    }
  }
`;

export const ABOUT = gql`
  query About {
    config {
      name
      description
      longDescription
      contact
      languages
      registrationsOpen
      registrationsAllowlist
      anonymous {
        participation {
          allowed
        }
      }
      version
      federating
      instanceFeeds {
        enabled
      }
    }
  }
`;

export const CONTACT = gql`
  query Contact {
    config {
      name
      contact
    }
  }
`;

export const RULES = gql`
  query Rules {
    config {
      rules
    }
  }
`;

export const PRIVACY = gql`
  query Privacy($locale: String) {
    config {
      privacy(locale: $locale) {
        type
        url
        bodyHtml
      }
    }
  }
`;

export const TIMEZONES = gql`
  query Timezones {
    config {
      timezones
    }
  }
`;

export const WEB_PUSH = gql`
  query WebPush {
    config {
      webPush {
        enabled
        publicKey
      }
    }
  }
`;

export const EVENT_PARTICIPANTS = gql`
  query EventParticipants {
    config {
      exportFormats {
        eventParticipants
      }
    }
  }
`;
