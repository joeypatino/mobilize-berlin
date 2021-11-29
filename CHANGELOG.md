# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.0.1 - 2021-11-26

### Changed

- Remove litepub context

### Fixed

- Make sure my group upcoming events are ordered by their start date
- Fix event participants pagination
- Always focus the search field after results have been fetched
- Don't sign fetches to instance actor when refreshing their keys
- Fix reject of already following instances
- Added missing timezone data to the Docker image
- Replace @tiptap/starter-kit with indidual extensions, removing unneeded extensions that caused issues on old Firefox versions
- Better handling of Friendica Update activities without actor information
- Always show pending/cancelled status on event cards
- Fixed nightly docker build
- Refresh loggeduser information before the final step of onboarding, avoiding loop when finishing onboarding
- Handle tz_world data being absent

### Translations

- Croatian (New !)
- Czech
- Gaelic
- Hungarian
- Indonesian
- Welsh (New !)

## 2.0.0 - 2021-11-23

Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Added

- Added possibility to follow groups and be notified from new upcoming events
- Export list of participants to CSV, `PDF` and `ODS`
- Allow to set timezone for an event. The timezone is automatically defined from the address if one is defined. If the event timezone is different than the user's current one, a toggle is shown to switch between the two.
- Added initial support for Right To Left languages (such as arabic) and [BiDi](https://en.wikipedia.org/wiki/Bidirectional_text)
- Group followers and members get an notification email by default when a group publishes a new event (subject to activity notification settings)
- Group admins can now approve or deny new memberships
- Build releases in `arm` and `arm64` format in addition to `amd64`
- Build Docker images in `arm` and `arm64` format in addition to `amd64`
- Added possibility to indicate the event is fully online
- Added possibility to search only for online events
- Added possibility to search only in past events
- Detect event, comments and posts languages automatically. Allows setting language
- Allow to change an user's password through the users.modify mix task
- Add instance setting so that only the admin can create groups
- Add instance setting so that only groups can create events
- Added JSON-LD metadata about the event in emails
- Added a quick link to email notification settings at the bottom of emails
- Allow to access Mobilizon with a specific language directly by using `https://instance.tld/lang` where `lang` is a language supported by Mobilizon
- Added organizer actor name (profile or group) in the icalendar export
- Add initial support for federation with Gancio

### Changed

- Multiple UI improvements, including post, event and participation cards, discussions and emails. The « My Events » page was also redesigned to allow showing events from your groups.
- Various accessibility improvements
- Event update notification is send to participants ~30 minutes after the event update, so that successive edits are throttled.
- Event, post and comments titles and content now have expose their detected language in HTML, for improved screen reader experience
- Delete current actor ID as well from local storage when unlogging
- Show a default text for instance contact in default terms text when no instance contact is set
- Only show locatecontrol button in leaflet map when we can do geolocation
- Disable push column in notification settings when push is not available
- Show actual language instead of language code in Users admin view
- Empty old & new passwords fields when successful password change
- Don't link to the group page from admin when actor is suspended
- Warn participants when the event organizer is suspended (and therefore the event cancelled)
- Improve metadata on public page
- Make sure some event action pages (participate remotely or without an account) don't get indexed by search engines
- Only send `Tombstone` element in `Delete` activities, not the whole previous deleted element.
- Make sure `Delete` activity are send correctly to everyone
- Only add address and tags to event icalendar export if they exist
- `master` branch has been renamed to `main`
- Mention following groups on the registration page
- Add missing group name to activity notifications
- Warn while registering and logging when the email contains uppercase characters
- Improve json-ld metadata on event live streams
- Add "eventAttendanceMode" to JSON-ld schema.org event representation
- Improve sending pending participation notifications
- Add "formerType" and "delete" attributes on Tombstones ActivityPub objects representation
- Improve MyEvents page description text

### Removed

- Support for Elixir < 1.12 and OTP < 22

### Fixed

- Fix tags autocomplete
- Fix config onboarding after LDAP initial connexion
- Fix events pagination on tags page
- Fixed deduplicated files from orphan media being deleted as well
- Fix deleting own account
- Fix search returning user profiles instead of only groups
- Fix federating geo coordinates
- Fix an issue with group activity items when moving resources
- Fix an issue with Identity Picker
- Fix an issue with TagInput
- Fix an issue when leaving a group
- Fix admin settings edition
- Fix an issue when showing public page of suspended group
- Removed non existing page (`/about/mobilizon`) from sitemap
- Fix action logs containing group suspension events
- Fixed group physical address not exposed to ActivityPub
- Release front-end files are no longer in duplicate
- Only show datetime timezone toggle on event if the timezone offset is different from our own
- Fix error when determining audience for Discussion when deleting a comment
- Fix a couple of accessibility issues
- Limit to acceptable tags when pasting raw HTML into comment fields on front-end
- Fixed group map display
- Fixed updating group physical address
- Allow group members to access group drafts
- Improve group refreshment workflow
- Fixed date signature generation for federation
- Fixed an issue when duplicating a group event from another profile
- Fixed event metadata not saved on eventcreation
- Use a different pagination parameter for searched events and featured events on search page
- Fixed creating group activities when creating events with some fields
- Move release package at correct path for CI upload
- Fixed event contacts that were not exposed and fetched over federation
- Don't sign fetch when fetching actor for a given signature
- Some various HTTP signatures issues
- Fixed actor AP representation of avatar
- Handle errors when fetching actor pictures
- Fixed sending group events to followers on Mastodon
- Fixed actors avatars and banners being deleted if the same file was also an orphan media
- Fix spacing in organizer picker
- Increase number of close events and follow group events
- Fix accessing user profile in admin section
- Set initial values for some EventMetadata elements, fixing submitting them right away with no value
- Avoid giving an error page if the apollo futureParticipations query is undefined
- Fixed path to exports in production
- Fixed padding below truncated title of event cards
- Fixed exports that weren't enabled in Docker
- Fixed error page when event end date is null
- Fixed event language not being allowed to be null

### Security

- Fixed private messages sent as event replies from Mastodon that were shown publically as public comments. They are now discarded.

### Translations

- Czech
- Gaelic
- German
- Hungarian
- Indonesian
- Norwegian Nynorsk
- Occitan
- Persian
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish


## 2.0.0-rc.3 - 2021-11-22

This lists changes since 2.0.0-rc.3. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Fixed

- Fixed path to exports in production
- Fixed padding below truncated title of event cards
- Fixed exports that weren't enabled in Docker
- Fixed error page when event end date is null

## 2.0.0-rc.2 - 2021-11-22

This lists changes since 2.0.0-rc.1. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Changed

- Improve MyEvents page description text

### Fixed
- Fix spacing in organizer picker
- Increase number of close events and follow group events
- Fix accessing user profile in admin section
- Set initial values for some EventMetadata elements, fixing submitting them right away with no value
- Avoid giving an error page if the apollo futureParticipations query is undefined
### Translations

- German
- Hungarian

## 2.0.0-rc.1 - 2021-11-20

This lists changes since 2.0.0-beta.2. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.

### Changed

- Mention following groups on the registration page
- Add missing group name to activity notifications
- Warn while registering and logging when the email contains uppercase characters
- Improve json-ld metadata on event live streams
- Add "eventAttendanceMode" to JSON-ld schema.org event representation
- Improve sending pending participation notifications
- Add "formerType" and "delete" attributes on Tombstones ActivityPub objects representation

### Fixed
- Fixed creating group activities when creating events with some fields
- Move release package at correct path for CI upload
- Fixed event contacts that were not exposed and fetched over federation
- Don't sign fetch when fetching actor for a given signature
- Some various HTTP signatures issues
- Fixed actor AP representation of avatar
- Handle errors when fetching actor pictures
- Fixed sending group events to followers on Mastodon
- Fixed actors avatars and banners being deleted if the same file was also an orphan media

### Translations

- Gaelic
- Spanish

## 2.0.0-beta.2 - 2021-11-15

This lists changes since 2.0.0-beta.1. Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.
### Added

- Group followers and members get an notification email by default when a group publishes a new event (subject to activity notification settings)
- Group admins can now approve or deny new memberships
- Added organizer actor name (profile or group) in the icalendar export
- Add initial support for federation with Gancio

### Changed

- Event update notification is send to participants ~30 minutes after the event update, so that successive edits are throttled.
- Event, post and comments titles and content now have expose their detected language in HTML, for improved screen reader experience

### Fixed

- Release front-end files are no longer in duplicate
- Only show datetime timezone toggle on event if the timezone offset is different from our own
- Fix error when determining audience for Discussion when deleting a comment
- Fix a couple of accessibility issues
- Limit to acceptable tags when pasting raw HTML into comment fields on front-end
- Fixed group map display
- Fixed updating group physical address
- Allow group members to access group drafts
- Improve group refreshment workflow
- Fixed date signature generation for federation
- Fixed an issue when duplicating a group event from another profile
- Fixed event metadata not saved on eventcreation
- Use a different pagination parameter for searched events and featured events on search page

### Translations

- Gaelic
- Spanish

## 2.0.0-beta.1 - 2021-11-09

Please read the [UPGRADE.md](https://framagit.org/framasoft/mobilizon/-/blob/main/UPGRADE.md#upgrading-from-13-to-20) file as well.
### Added

- Added possibility to follow groups and be notified from new upcoming events
- Export list of participants to CSV, `PDF` and `ODS`
- Allow to set timezone for an event. The timezone is automatically defined from the address if one is defined. If the event timezone is different than the user's current one, a toggle is shown to switch between the two.
- Added initial support for Right To Left languages (such as arabic) and [BiDi](https://en.wikipedia.org/wiki/Bidirectional_text)
- Build releases in `arm` and `arm64` format in addition to `amd64`
- Build Docker images in `arm` and `arm64` format in addition to `amd64`
- Added possibility to indicate the event is fully online
- Added possibility to search only for online events
- Added possibility to search only in past events
- Detect event, comments and posts languages automatically. Allows setting language
- Allow to change an user's password through the users.modify mix task
- Add instance setting so that only the admin can create groups
- Add instance setting so that only groups can create events
- Added JSON-LD metadata about the event in emails
- Added a quick link to email notification settings at the bottom of emails
- Allow to access Mobilizon with a specific language directly by using `https://instance.tld/lang` where `lang` is a language supported by Mobilizon

### Changed

- Multiple UI improvements, including post, event and participation cards, discussions and emails. The « My Events » page was also redesigned to allow showing events from your groups.
- Various accessibility improvements
- Delete current actor ID as well from local storage when unlogging
- Show a default text for instance contact in default terms text when no instance contact is set
- Only show locatecontrol button in leaflet map when we can do geolocation
- Disable push column in notification settings when push is not available
- Show actual language instead of language code in Users admin view
- Empty old & new passwords fields when successful password change
- Don't link to the group page from admin when actor is suspended
- Warn participants when the event organizer is suspended (and therefore the event cancelled)
- Improve metadata on public page
- Make sure some event action pages (participate remotely or without an account) don't get indexed by search engines
- Only send `Tombstone` element in `Delete` activities, not the whole previous deleted element.
- Make sure `Delete` activity are send correctly to everyone
- Only add address and tags to event icalendar export if they exist
- `master` branch has been renamed to `main`

### Removed

- Support for Elixir < 1.12 and OTP < 22

### Fixed

- Fix tags autocomplete
- Fix config onboarding after LDAP initial connexion
- Fix events pagination on tags page
- Fixed deduplicated files from orphan media being deleted as well
- Fix deleting own account
- Fix search returning user profiles instead of only groups
- Fix federating geo coordinates
- Fix an issue with group activity items when moving resources
- Fix an issue with Identity Picker
- Fix an issue with TagInput
- Fix an issue when leaving a group
- Fix admin settings edition
- Fix an issue when showing public page of suspended group
- Removed non existing page (`/about/mobilizon`) from sitemap
- Fix action logs containing group suspension events
- Fixed group physical address not exposed to ActivityPub

### Security

- Fixed private messages sent as event replies from Mastodon that were shown publically as public comments. They are now discarded.
### Translations

- Czech
- Gaelic
- German
- Indonesian
- Norwegian Nynorsk
- Occitan
- Persian
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 1.3.2 - 2021-08-23

### Fixed

- Fixed deduplicated files from orphan media being cleanup as well
- Fixed config onboarding after initial connection
- Fixed current actor ID not being deleted from localstorage after logout
- Fixed missing pagination on tag exploring page
- Fixed deleting own account
- Fixed user profiles that could show up in group search
- Fixed accessibility issues on the account settings page

## 1.3.1 - 2021-08-20

### Fixed

- Fixed default listen IP and sitemap creation for Docker configurations
- Fixed issues related to user timezone setting being shown as set when it wasn't, leading to timezone sometimes missing and causing issues (#746, #815)
- Fixed issues with managing resources (#837, #838)

### Translations

- Gaelic
- Finnish
- Spanish

## 1.3.0 - 2021-08-17

### Added

- **Allow remote group moderators to edit group events and posts**
- **Allow events to hold metadata information, either preconfigured (live video URL, price details, accessibility informations,…), either through a free key/value form.** Metadata concerning live video feeds linking to PeerTube, YouTube & Twitch will benefit from iframe integration.
- Add the possibility to create profiles and groups from CLI
- Add the possibility to create a profile at the same time when creating an user from CLI
- Add the possibility to create users with LDAP provider from CLI
- Added back support for Docker-compose based development
- Added rel=canonical and meta robots noindex tags to public pages from remote groups, in order to avoid them being indexed by Google
- Allow members-restricted posts to be viewable by instance moderators (for moderation purposes)
- Added a filter to resize pictures bigger than 1920x1080
- Allow to deny registration by email or email domain
- Added missing index on participants url
- Added a loading wheel to show that events are loading on some views

### Changed

- Made server only listen on IPv4 in the install template
- Improve identity picker to have a fixed height and allow filtering between your identities and group contacts
- Leaflet map controls (zoom/locate) are now translatable
- Show exactly 12 events on the Explore page

### Fixed

- Fixed links contained in event & post description that didn't open in new tabs
- Add back missing RSS/ical links on public group pages 
- Fixed links to Framacolibri forum
- Fixed drafts and restricted visibility events & posts listed on group page
- Fixed notification page on Safari
- Fixed profile edition
- Fixed Feed Token recreation
- Fixed media cleaner job
- Fixed english being always used as a language instead of the default one set when the request has no `Accept-Language` header (such as Google index bots)
- Fixed Ecto validation errors not being translated and interpolated
- Fixed <html> `lang` attribute not being properly set with the language currently used
- Fixed federated posts having wrong visibility setting
- Fixed unused CSS filter on homepage rendering wrong on Webkit
- Fixed handling SSL being already started in LDAP connection
- Fixed an Apollo cache issue when registrering your first profile
- Fixed the Docker image missing ca-certificates
- Fixed missing pagination on Explore page featured events
- Fixed broken popup warning when editing an event
- Fixed GraphQL Playground (again)
- Fixed Coordinates mixmatch between latitude and longitude in iCalendar export and federation
- Fixed token refreshment issues
- Fixed search from 404 page


### Translations

- Catalan
- Chinese (Traditional)
- Finnish
- French
- Gaelic
- Galician
- German
- Indonesian
- Russian
- Spanish

## 1.2.3 - 2021-07-02

### Changed

- Improved list discussion items UI on the group panel

### Fixed

- Fixed 'unsafe-inline' being in CSP
- Fixed group discussions with deleted comments

## 1.2.2 - 2021-07-01
### Changed

- Improved UI for participations when message is too long 

### Fixed

- Fixed pictures without metadata information in post display
- Fixed crash when trying to notify activities not from groups
- Fixed imagemagick missing from Dockerfile
- Fixed push notifications for group, members & post activities
- Fixed ellipsis in DiscussionListView 
- Fixed submission button for posts not visible on mobile
- Fixed remote profile suspension

### Translations

- Spanish

## 1.2.1 - 2021-06-29

### Fixed

- Fixed Docker image missing libc (which is required by newer OTP versions at runtime)
- Fixed compatibility check in Notification section for service workers

## 1.2.0 - 2021-06-29
### Added

- **Notifications for various group and event activity, both by email and browser push notifications. Daily and weekly digests are also available.**
- Possibility for an event organizer to announce a (public) comment, triggering notifications for participants
- Add a snackbar message to manually reload the UI when updates are available
- Add blurhash support for some banners
- Added basic metadata (start time & physical address) in the opengraph preview

### Changed

- **Interface improvements to events, comments, homepage and group pages**
- **Various improvements to mobile views**
- Make JWT access tokens short-lived
- Disabled Cldr warning that the `Cldr.Plug.AcceptLanguage` plug didn't many any known locale
- Replaced GraphiQL web interface with graphql-playground 

### Removed

- Internet Explorer and other older browsers support. This allows us to provide lighter builds.

### Fixed

- Fixed compatibility for previous OTP versions
- Fixed the "member joined" activity event not being displayed in the group activity timeline
- Fixed relay and anonymous actor telling they automatically approve followers
- Fixed mix tasks showing output from all error levels
- Fixed missing metadata on some pages
- Fixed some config values being defined at compile-time instead of runtime
- Fixed missing pagination for group resources
- Fixed missing `.ics` suffix for email event attachments
- Fixed missing unique index on posts URL
- Fixed creating events from group page not always auto-selecting the correct organizer actor
- Fixed error when deleting actor with type different from Person or Group
- Fixed not defaulting to UTC timezone when user has no tz setting in their activity recaps
- Fixed Sentry loading itself even if not configured
- Fixed showing proper message when anonymous participation was confirmed but just wasn't saved in browser
- Fixed editing some event properties
- Fixed group image ratio in admin dashboard
- Fix GraphiQL CSP headers

### Translations

- Finnish
- French
- Galician
- Italian
- Occitan
- Russian
- Spanish
- Swedish

## 1.2.0-beta.3 - 2021-06-27

### Added

- Allow sending notifications to event organizer when new comment is posted
- Allow sending comment announcements notifications to anonymous participants as well

### Changed

- Disabled Cldr warning that the `Cldr.Plug.AcceptLanguage` plug didn't many any known locale

### Fixed

- Fixed error when deleting actor with type different from Person or Group
- Fixed not defaulting to UTC timezone when user has no tz setting in their activity recaps
- Fixed Sentry loading itself even if not configured
- Fixed showing proper message when anonymous participation was confirmed but just wasn't saved in browser
- Fixed editing some event properties

### Translations

- Persian (New!)
- Spanish

## 1.2.0-beta.2 - 2021-06-26

### Added

- Added basic metadata (start time & physical address) in the opengraph preview
- Made mentions trigger notifications
- Allow to send activity digests
- Mix task to generate web push keypair

### Fixed

- Fixed missing unique index on posts URL
- Fixed creating events from group page not always auto-selecting the correct organizer actor

### Translations

- French
- Spanish

## 1.2.0-beta.1 - 2021-06-21

### Added

- **Notifications for various group and event activity, both by email and browser push notifications**
- Possibility for an event organizer to announce a (public) comment, triggering notifications for participants
- Add a snackbar message to manually reload the UI when updates are available
- Add blurhash support for some banners

### Changed

- **Interface improvements to events, comments, homepage and group pages**
- **Various improvements to mobile views**
- Make JWT access tokens short-lived

### Removed

- Internet Explorer and other older browsers support. This allows us to provide lighter builds.

### Fixed

- Fixed compatibility for previous OTP versions
- Fixed the "member joined" activity event not being displayed in the group activity timeline
- Fixed relay and anonymous actor telling they automatically approve followers
- Fixed mix tasks showing output from all error levels
- Fixed missing metadata on some pages
- Fixed some config values being defined at compile-time instead of runtime
- Fixed missing pagination for group resources
- Fixed missing `.ics` suffix for email event attachments

### Translations

- Finnish
- Galician
- Italian
- Occitan
- Russian
- Spanish
- Swedish

## 1.1.4 - 2021-05-19

### Fixes

- Fixes rich media parsers, so that some resource links work again
- Fixes some depreciated calls that were removed in OTP24
- Fixes groups not being refreshed after joining a group
- Fixes the notice that is shown when joining a group that the content may not be available right away - because the group is remote - being shown everytime, even when the group is local
- Fixes OGP image not being defined for posts

### Translations

- French
- Galician
- Italian

## 1.1.3 - 2021-05-03

### Changed

- Lower the frequency for refreshment of external groups

### Fixes

- Fixed spaces being eaten in the rich text editor (event description, comments and public posts)
- Fixed event physical address display
- Fixed tags being limited to 20 characters
- Fixed some ActivityPub errors

### Translations

- Galician
- Russian
- Spanish

## 1.1.2 - 2021-04-28

### Changed

- Added an unique index on the addresses url
- Added org.opencontainers.image.source annotation to the Docker image 
- Improved the moderation action logs interface

### Fixes

- **Fixed some invalid email headers**
- **Fixed and repaired default profile still pointing on deleted profile**
- Fixed some ActivityPub issues and improve error handling
- Fixed a duplicate sentence in the email changed html template
- Fixed resource metadata remote image URL
- Fixed not only remote groups being refreshed after the acceptation of an invite
- Fixed an UI overflow on the organizer metadata block if the organizer remote username is too long

### Translations

- Italian
- German
- Slovenian
- Russian

## 1.1.1 - 2021-04-22

### Changed

- Allow to remove user location setting and location information on an event or group
- Instance level feeds are now shown on the instance About page, and are exposed as `rel=alternate` links, if instance level feeds are activated in the config
- Webfinger module now queries the host-meta XRD endpoint to detect the webfinger well-known endpoint
- Instance maximum upload sizes are now exposed in the API
- Improve handling of media files which are too heavy
- Improve details when editing or showing an user through CLI
- More strict browser compatibility
- Renamed "Close events" to "Nearby events" ("close" is too close to "closed")
- Improved Sentry integration

### Fixes

- Fixed accessing a group discussion page without being a member (the page was just broken)
- Fixed reloading the members list after excluding a member
- Fixed comments being closed under an event message when not connected
- Fixed path issue when fetching favicon for resources
- Fixed content type and size missing for profile avatars
- Fixed HTTP clients user-agent not using runtime configuration
- Fixed the `support` folder not being copied into releases
- Fixed the participation button position when text is too long or in some cases
- Fixed the incorrect CSP configuration
- Fixed discussions being sent to followers instead of members
- Fixed showing broken public UI for deleted/suspended group
- Fixed warning when getting out of creating/editing an unsaved event that was broken for some languages
- Fixed addresses being not trimmed in the iCalendar exports
- Fixed editing an user's email in CLI
- Fixed suspended actors being refreshed

### Translations

- Gaelic
- German
- Kabyle (New!)
- Norwegian
- Russian
- Slovenian
- Spanish

## 1.1.0 - 2021-03-31

This version introduces a new way to install and host Mobilizon : Elixir releases. This is the new default way of installing Mobilizon. Please read [UPGRADE.md](./UPGRADE.md#upgrading-from-10-to-11) for details on how to migrate to Elixir binary releases or stay on source install.

### Added

- **Add a group activity logbook**
- **Possibility for user to define a location in their settings to get close events**
- **Support for Elixir releases and runtime.exs, allowing to change configuration without recompiling**
- Support for Sentry
- Added support for custom plural rules on front-end (only Gaelic supported for now)
- Added possibility to bookmark search by location through geohash
- Add ENV parameter to allow Docker users to specify the IP which Mobilizon listens on
- Add instance-wide ICS & Atom feeds of public events (disabled by default)
- Add user and profile secret (tokened) feeds
- Runit configuration files

### Changed

- Prune done background jobs
- Improved search form
- Improved backend error page
- Added a confirmation step before deleting a conversation
- The default configuration for Mobilizon now listens only on the local interface
- Creating an event from the group page configures the event creation interface with the group as organizer
- Only provide executables for unix

### Removed

- Support for Elixir versions < 1.11

### Fixes

- Fixed editing a group discussion
- Fixed accessing terms and privacy pages
- Fixed refreshing only groups which are stale
- Fixed success message when validating group follower
- Fixed formatted dates using system locale instead of browser/Mobilizon's locale
- Fixed federating draft status
- Fixed group draft posts being sent to followers
- Fixed detecting membership status on group page
- Fixed admin language selection
- Fixed geospatial configuration only being evaluated at compile-time, not at runtime
- Handle ActivityPub Fetcher returning text that's not JSON
- Fix accessing a group profile when not a member
- Fixed accessing the homepage with no location setting defined
- Fixed location field not showing in preferences if setting not already set
- Fixed lasts events published order on the homepage
- Fixed a typo in range/radius showing the wrong radius for close events on homepage
- Fixed hashtags disappearing from content
- Fixed close events order
- Fixed group posts edition
- Fixed validating new email with bad token
- Fixed `.well-known/host-meta` not being accessible with correct `Accept` header
- Fixed posts default publish date overriding remote ones
- Fixed getting a page description in some cases when creating a resource
- Fixed getting metadata from tweets when creating a resource
- Fixed bad handling of duplicate usernames
- Fixed handling of bad URIs to proxify
- Fixed creating discussion with title containing only spaces 
- Fixed registering new user account with same email as unconfirmed
- Fixed handling changing default actor unlogged
- Fixed handling getting organized events from an actor when not authorized
- Fixed empty comments being allowed
- Fixed the number of group followers per page
- Fixed issue when selecting a location in your settings
- Fixed group feeds not showing when you are a member of the group
- Fixed handling feeds with unknown format
- Fixed a couple of issues when viewing a remote group
- Fixed issues with the attributed organizer when creating an event
- Fixed HTML entities not being decoded in icalendar exports and feeds
- Fixed instance follows being auto-approved
- Fixed parsing the IP from the MOBILIZON_INSTANCE_LISTEN_IP env variable for Docker
- Fixed release startup in Docker container

### Translations

- Arabic
- Belarusian
- Bengali
- Catalan
- Chinese (Traditional)
- English
- French
- Gaelic **New!**
- Galician
- German
- Hungarian
- Italian
- Occitan
- Polish
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 1.1.0-rc.3 - 2021-03-30

### Changed

- Only provide executables for unix

### Fixed

- Fixed parsing the IP from the MOBILIZON_INSTANCE_LISTEN_IP env variable for Docker
- Fixed release startup in Docker container

## 1.1.0-rc.2 - 2021-03-30

### Added

- Runit configuration files

### Fixed

- Fixed the number of group followers per page
- Fixed issue when selecting a location in your settings
- Fixed group feeds not showing when you are a member of the group
- Fixed handling feeds with unknown format
- Fixed a couple of issues when viewing a remote group
- Fixed issues with the attributed organizer when creating an event
- Fixed HTML entities not being decoded in icalendar exports and feeds
- Fixed instance follows being auto-approved

### Translations

- Galician
- German
- Hungarian
- Russian
- Spanish
## 1.1.0-rc.1 - 2021-03-29

### Added

- Add ENV parameter to allow Docker users to specify the IP which Mobilizon listens on
- Add instance-wide ICS & Atom feeds of public events (disabled by default)
- Add user and profile secret (tokened) feeds

### Changed

- The default configuration for Mobilizon now listens only on the local interface
- Creating an event from the group page configures the event creation interface with the group as organizer

### Fixed

- Fixed hashtags disappearing from content
- Fixed close events order
- Fixed group posts edition
- Fixed validating new email with bad token
- Fixed `.well-known/host-meta` not being accessible with correct `Accept` header
- Fixed posts default publish date overriding remote ones
- Fixed getting a page description in some cases when creating a resource
- Fixed getting metadata from tweets when creating a resource
- Fixed bad handling of duplicate usernames
- Fixed handling of bad URIs to proxify
- Fixed creating discussion with title containing only spaces 
- Fixed registering new user account with same email as unconfirmed
- Fixed handling changing default actor unlogged
- Fixed handling getting organized events from an actor when not authorized
- Fixed empty comments being allowed

### Translations

- Gaelic
- Galician
- German
- Hungarian
- Italian
- Polish
- Portuguese (Brazil)
- Russian
- Slovenian
- Spanish

## 1.1.0-beta.6 - 2021-03-17

### Fixed
- Fixed a typo in range/radius showing the wrong radius for close events on homepage

## 1.1.0-beta.5 - 2021-03-17

### Fixed
- Fixed a typo in range/radius preventing close events from showing up

## 1.1.0-beta.4 - 2021-03-17

### Fixed

- Fixed accessing the homepage with no location setting defined
- Fixed location field not showing in preferences if setting not already set
- Fixed lasts events published order on the homepage

## 1.1.0-beta.3 - 2021-03-16

### Fixed
- Handle ActivityPub Fetcher returning text that's not JSON
- Fix accessing a group profile when not a member

## 1.1.0-beta.2 - 2021-03-16

### Fixed
- Fixed geospatial configuration only being evaluated at compile-time, not at runtime

### Translations
- Slovenian

## 1.1.0-beta.1 - 2021-03-10

This version introduces a new way to install and host Mobilizon : Elixir releases. This is the new default way of installing Mobilizon. Please read [UPGRADE.md](./UPGRADE.md#upgrading-from-10-to-11) for details on how to migrate to Elixir binary releases or stay on source install.

### Added

- **Add a group activity logbook**
- **Possibility for user to define a location in their settings to get close events**
- **Support for Elixir releases and runtime.exs, allowing to change configuration without recompiling**
- Support for Sentry
- Added support for custom plural rules on front-end (only Gaelic supported for now)
- Added possibility to bookmark search by location through geohash

### Changed

- Prune done background jobs
- Improved search form
- Improved backend error page
- Added a confirmation step before deleting a conversation

### Removed

- Support for Elixir versions < 1.11

### Fixes

- Fixed editing a group discussion
- Fixed accessing terms and privacy pages
- Fixed refreshing only groups which are stale
- Fixed success message when validating group follower
- Fixed formatted dates using system locale instead of browser/Mobilizon's locale
- Fixed federating draft status
- Fixed group draft posts being sent to followers
- Fixed detecting membership status on group page
- Fixed admin language selection

### Translations

- Arabic
- Belarusian
- Bengali
- Catalan
- Chinese (Traditional)
- English
- French
- Gaelic
- Galician
- German
- Hungarian
- Italian
- Occitan
- Portuguese (Brazil)
- Slovenian
- Spanish
- Russian

## 1.0.7 - 2021-02-27

### Fixed

- Fixed accessing group event unlogged
- Fixed broken redirection with Webfinger due to strict connect-src
- Fixed editing group discussions
- Fixed search form display
- Fixed wrong year in CHANGELOG.md

## 1.0.6 - 2021-02-04

### Added

- Handle frontend errors nicely when mounting components

### Fixed

- Fixed displaying a remote event when organizer is a group
- Fixed sending events & posts to group followers
- Fixed redirection after deleting an event

## 1.0.5 - 2021-01-27

### Fixed

- Fixed duplicate entries in search with empty search query

## 1.0.4 - 2021-02-26

### Added

- **Added interface to approve/reject group follow requests**
- **Added UI for group public RSS (Atom) / ICS feeds**
- **Attach ICS files representing the event to notifications and participations emails**
- Add initial support to build Elixir releases
- Add some CSP & other security headers

### Changed

- Added `<hr>` to allowed HTML tags
- Events are now correctly ordered by their beginning date on search and group page
- Improve resource metadata parsing by restricting OGP/Twitter metadata to an allowed list of attributes
- Reverse proxy pictures from resource metadata (favicons & such)

### Fixed

- **Fixed group remote subscription**
- Upgrade PWA support library to avoid a call to Google CDN
- Fixed group avatar & banner upload
- Fixed some events not showing on homepage
- Fixed the `next` and `prev` attribute not being present in `CollectionPage` ActivityPub Collections
- Added a text to explain that group discussions are restricted to members on discussion list page
- Fixed ICS export timezone issues
- Fixed remote interactions when the content was not local to the instance
- Fixed a federation issue with group member removal
- Hide event organiser profile through the GraphQL API when a group is the organizer
- Fix an issue where the event form datepickers where displayed under the address map

### Translations

- Bengali (New!)
- Catalan
- Finnish
- French
- Galician
- German
- Italian
- Norwegian
- Polish
- Portuguese (New!)
- Slovenian (New!)
- Spanish
- Swedish

## 1.0.3 - 2020-12-18

**This release adds new migrations, be sure to run them before restarting Mobilizon**

**This release has repair steps, be sure to execute them right after restarting Mobilizon**

### Special operations

* **Reattach media files to their entity.**
  When media files were uploaded and added in events and posts bodies, they were only attached to the profile that uploaded them, not to the event or post. This task attaches them back to their entity so that the command to clean orphan media files doesn't remove them.

  * Source install
    `MIX_ENV=prod mix mobilizon.maintenance.fix_unattached_media_in_body`
  * Docker
    `docker-compose exec mobilizon mobilizon_ctl maintenance.fix_unattached_media_in_body`

* **Refresh remote profiles to save avatars locally**
  Profile avatars and banners were previously only proxified and cached. Now we save them locally. Refreshing all remote actors will save profile media locally instead.

  * Source install
    `MIX_ENV=prod mix mobilizon.actors.refresh --all`
  * Docker
    `docker-compose exec mobilizon mobilizon_ctl actors.refresh --all`

* **imagemagick and webp are now a required dependency** to build Mobilizon.
  Optimized versions of Mobilizon's pictures are now produced during front-end build.
  See [the documentation](https://docs.joinmobilizon.org/administration/dependencies/#misc) to make sure these dependencies are installed.

### Added

- **Add a command to clean orphan media files**. There's a `--dry-run` option to see what files would have been deleted.  
  **Make sure all media files have been reattached properly (see above) before running this command.**  
  In 1.1.0 a scheduled job will be enabled to clear orphan media files automatically after a while.
- Added user and actors media usage information in administration
- Added a scheduled job to clean unconfirmed users (and their eventual initial profile) after a 48 hour grace period
- Added a mix task to manually clean unconfirmed users
- Added OpenStreetMap (OSRM) or GoogleMaps routing pages on the event map modal
- Added PWA support, Mobilizon can now be installed on Android (Firefox and Chrome), iOS (Safari) and desktop (Chrome)
- Added possibility to pick language through a setting on the footer for unlogged users

### Changed

- Save remote avatars and banners instead of proxifying them
- Forbid creating usernames with uppercase characters
- Allow LDAP admin to use a fully qualified DN (different than the one for the users)
- Allow LDAP users to be filtered by LDAP attribute `memberOf`.
- Improve the "My events" and "My groups" page when there's nothing here yet
- Show identity concerned when listing event participations (in "My events") and group membership (in "My groups")
- The datetime picker on the event's edition page has been changed and allows directly editing the text
- Allow to clear and remove pictures from events and posts

### Fixed

- Fixed inline media that weren't being tracked, so that they are not considered orphans media files.
- Fixed permissions on the Docker volume
- Fixed emails not using user timezone
- Fixed draft status not being shown on group events & posts inside admin section
- Fixed cancelled status not being shown on cancelled events cards
- Fixed membership notification emails not being sent with the user's language
- Fixed group posts ActivityPub endpoint
- Fixed unlisted groups being available in search
- Fixed inline media pictures being unattached when editing an event or a post
- Fixed adding an instance to follow with spaces
- Fixed past groups showing up on group's page
- Fixed error message not showing up when you are already an anonymous participant for an event
- Fixed error message not showing up when you pick an username already in user for a new profile or a group
- Fixed translations not fallbacking properly to english when not found
- 

### Security

- Stop logging user JWT tokens in Websocket Mobilizon logs

### Translations

Updated translations:
- Catalan
- Dutch
- English
- Finnish
- French
- Galician
- German
- Hungarian
- Italian
- Norwegian
- Occitan
- Polish
- Spanish
- Swedish

## 1.0.2 - 2020-11-15

**This release adds new migrations, be sure to run them before restarting Mobilizon**

### Changed

- PostgreSQL extensions creations are now automatically handled in the Docker's entrypoint

### Fixed

- Fixed an issue with Oban migrations and some PostgreSQL versions
- Fixed an issue that causes email not being able to be sent when the `TZ` environment variable is not available
- Fixed 3rd-party login Ueberauth providers not being usable if configured at runtime

### Translations

- Catalan
- Hungarian
- Italian
- Occitan

## 1.0.1 - 2020-11-14

**This release adds new migrations, be sure to run them before restarting Mobilizon**

### Added

- **Possibility to join open groups** (local and remote). Possibility in the group settings to pick if the group is open to new members or not.
  Note: The group default setting is closed. You need to manually set your group as open in the group settings.
- **Docker support** (@Pascoual). See [documentation](https://docs.joinmobilizon.org/administration/docker/)
- Added steps to the onboarding process on first login, including a profile and federation presentation step
- Added a regular job to refresh remote groups once in a while

### Changed

- Adapted the demo mode to reflect changes (Mobilizon is no longer in beta)
- User language is now saved in localStorage (allowing to load the right locale right away, and in the future allowing to pick custom language without account https://framagit.org/framasoft/mobilizon/-/issues/375)

### Fixed

- Fixed group list, group members and instance followers/followings pagination
- Fixed detecting file MIME type if the file hasn't got a filename
- Changed a few sentences that didn't sounded english (@mkljczk)
- Fixed instance custom privacy policy not being applied
- Fixed demo warning always displaying on the text version of emails
- Fixed language picker not loading languages and saving the preference
- Fixed groups created without collections URLs and added a repair step to add them to local groups where these are missing
- Handle accessing instance followers/followings unlogged
- Made sure we only have a single instance relay actor
- Fixed about page crashing when the instance was configured with languages that Mobilizon doesn't support itself
- Don't allow remote comments under events if the event doesn't allow comments
- Fixed notification settings not displaying as saved
- Fixed pictures not being served by `Plug.Static`
- Fixed emails missing `Date` and `Message-ID` headers
- Fixed onboarding not saving language/timezone/notification settings

### Translations

- Basque
- Catalan
- Esperanto
- Finnish
- French
- Galician
- German
- Hungarian
- Italian
- Kannada
- Occitan
- Norwegian Nynorsk
- Polish
- Spanish

## 1.0.0 - 2020-10-26

### Changed

- Strengthen upload picture and filter code and tests
- Add link to mobilizon.org on the bottom of the about page to register

### Fixed

- Fix several front-end routes being accessible without authentification and make them redirect to login page (no information was given, the pages were just empty)
- Fallback version code to Mix project version value if there's no Git information
- Fix identity avatar change flicking or showing wrong avatar for identity
- Fix public group page when description/list of events/list of posts are empty
- Make sure `"to"` and `"cc"` in ActivityStreams are always lists (@vpzomtrrfrt)
- Check port when comparing URLs (@vpzomtrrfrt)

### Translations

- Galician
- German
- Occitan
- Spanish

## 1.0.0-rc.4 - 2020-10-22

### Fixed

- Fix an issue with group event listing

## 1.0.0-rc.3 - 2020-10-22

### Added

- Task to refresh a remote instance (crawling their outbox, fetching their latest public events just in case of federation issues)
- New homepage with illustration

### Fixed

- Handle timezone not detected inside browser
- Fix webfinger not following redirections
- Fix some Apollo GraphQL errors
- Disable updating/deleting group posts and discussions for non-moderators
- Fix group drafts events showing up on group public page

## 1.0.0-rc.2 - 2020-10-20

### Added

- Show if user is disabled in [`mix mobilizon.users.show` task](https://docs.joinmobilizon.org/administration/CLI%20tasks/manage_users/#show-an-users-details)
- Improved [ActivityPub documentation](https://docs.joinmobilizon.org/contribute/activity_pub/), especially for group federation.
- Show instance languages on instance about page
- Add fancy pictures on footer and 404 page

### Changed

- The [`mix mobilizon.users.delete` task](https://docs.joinmobilizon.org/administration/CLI%20tasks/manage_users/#delete-an-user) behaviour completely deletes the user, unless the `--keep_email` option is given (can be used to prevent someone registering again with the same email).
- Deleting your own account completely deletes user information (it previously kept the email information).
- The administration dashboard now shows more information on local events, groups and followed/following instances

### Fixed

- Significantly improve front-end build times and build in modern mode (with ES modules). The front-end payload is also quite lighter (loads each view asynchronously)
- Don't count deactivated/suspended users in public statistics
- Fix account settings for 3rd-party auth users
- Disable sending reset password emails to disabled users
- Fix display of event edit page on mobile
- Fix events from former followed instances showing up on explore page or in search
- The member management has received a couple fixes
- Handle issue when nothing was found when doing a reverse geocode (when drag&dropping the marker on map)
- Fix issue when searching by username with our own domain
- Fix issue with wrong redirection for remote groups when deleting a post
- Make sure only group moderators (and higher) can update/delete group events and group posts.
- Fix OEmbed preview generator parser
- Fix an issue with hostname validator in preview generator

### Translations

- Spanish
- Galician

## 1.0.0-rc.1 - 2020-10-12

### Special operations

* We added `application/ld+json` as acceptable MIME type for ActivityPub requests, so you'll need to recompile the `mime` library we use before recompiling Mobilizon:
    ```
    MIX_ENV=prod mix deps.clean mime --build
    ```

* The [nginx configuration](https://framagit.org/framasoft/mobilizon/-/blob/main/support/nginx/mobilizon.conf) has been changed with improvements and support for custom error pages.

* The cmake dependency has been added (see [our documentation](https://docs.joinmobilizon.org/administration/dependencies/#basic-tools))

### Added

- Possibility to login using LDAP
- Possibility to login using OAuth providers
- Enabled group features in production mode 
  - including posts (that can be public, unlisted, or restricted to your group members)
  - resources (collections of links, with folders, accessible to your group members)
  - discussions (group private and organized chats)
  - group events (events can be published by groups - and show some event members as contacts)
  - roles for members (member, moderator, administrator)
  - admin section to manage (suspend) groups
- Sitemap support (for public content) at `sitemap.xml`
- Searching events and groups with location
- More statistics are exposed through the `statistics` GraphQL query

### Changed

- Completely replaced HTMLSanitizeEx with FastSanitize [!490](https://framagit.org/framasoft/mobilizon/-/merge_requests/490)

### Fixed

- Fixed notification scheduler [!486](https://framagit.org/framasoft/mobilizon/-/merge_requests/486)
- Fixed event title escaping [!490](https://framagit.org/framasoft/mobilizon/-/merge_requests/490)
- Various implements in interface thanks to feedback

### Security

- Fix group settings being accessible and editable by non-group-admins (thx @pigpig for reporting this responsibly)
- Fix events being editable by profiles without permissions (thx @pigpig for reporting this responsibly) 

## [1.0.0-beta.3] - 2020-06-24

### Special operations
Config has moved from `.env` files to a more traditional way to handle things in the Elixir world, with `.exs` files.

To migrate existing configuration, you can simply run `mix mobilizon.instance gen` and fill in the adequate values previously in `.env` files (you don't need to perform the operations to create the database).

A minimal file template [is available](https://framagit.org/framasoft/mobilizon/blob/main/priv/templates/config.template.eex) to check for missing configuration.

Also make sure to remove the `EnvironmentFile=` line from the systemd service and set `Environment=MIX_ENV=prod` instead. See [the updated file](https://framagit.org/framasoft/mobilizon/blob/main/support/systemd/mobilizon.service).

### Added
- Possibility to participate to an event without an account (confirmation through email required)
- Possibility to participate to a remote event (being redirected by providing federated identity)
- Possibility to add a note as a participant when event participation is manually validated (required when participating without an account)
- Email notifications for events (one hour before, on the day of the event, each week)
- Email notifications for pending participation approval requests (disabled, directly, at most 1 per hour, at most 1 per day)
- Possibility to change email address for the account
- Possibility to delete your account
- Duplicate an event
- Ability to handle basic administration settings in the admin panel
- Config option to allow anonymous reporting
- Basic user and profile management admin interface to suspend local users or remote profiles
- Default Terms of service and Privacy policies
- As an admin, possibility to add rules and contact information
- Allow user to change language

### Changed
- Configuration handling (see above)
- Improved a bit color theme
- Signature validation also now checks if `Date` header has acceptable values
- Actor profiles are now stale after two days and have to be refetched
- Actor keys are rotated some time after sending a `Delete` activity
- Improved event participations managing interface
- Added physical address change to the list of important changes that trigger event notifications
- Improved public event page

### Fixed
- Fixed URL search
- Fixed content accessed through URL search being public
- Fix event links in some emails

## [1.0.0-beta.2] - 2019-12-18

### Special operations
These two operations couldn't be handled during migrations.
They are optional, but you won't be able to search or get participant stats on existing events if they are not executed.
These commands will be removed in Mobilizon 1.0.0-beta.3.

In order to populate search index for existing events, you need to run the following command (with prod environment):
* `mix mobilizon.setup_search`

In order to move participant stats to the event table for existing events, you need to run the following command (with prod environment):
* `mix mobilizon.move_participant_stats`

### Added
- Federation is active
- Added an interface for admins to view and manage instance followers and followings
- Ability to comment below events
- Implement search engine & service in backend **(read special instructions above)**
- Allow WebP and Gif pics upload
- Optimize uploaded pics
- Make tags clickable, redirecting to search
- Added a websocket API call to check if your participation status has changed
- Add a different welcome message when coming from registration
- Link to participation page from event page when you are an organizer
- Added several mix commands to manage users and view actors (`mix mobilizon.users` and `mix mobilizon.actors`) and their documentation
- Added a demo mode to show or hide instance warning
- Added a config option to whitelist users emails or email domains
- Updated Occitan translations (Quentin)
- Updated French translations (Gavy, Zilverspar, ty kayn, numéro6)
- Updated Swedish translations (Anton Strömkvist, Filip Bengtsson)
- Updated Polish translations (Marcin Mikolajczak)
- Updated Italian translations (AlessiBilos)
- Updated Arabic translations (Butterflyoffire)
- Updated Catalan translations (fadelkon, Francesc)
- Updated Belarusian translations (fadelkon)
- Upgraded frontend and backend dependencies

### Changed
- Move participant stats to event table **(read special instructions above)**
- Limit length (20 characters) and number (10) of tags allowed
- Added some backend changes and validation for field length
- Handle error message difference between user not found and user not confirmed
- Make external links (from URL field and description) open in a new tab with `noopener`
- Improve Docker setup and docs
- Upgrade vue-cli to v4, change the way server params injection is made
- Improve some production ipv6 configuration
- Limited year range in the DatePicker
- Event title is now clickable on cards (Léo Mouyna)
- Also consider the PeerTube `CommentsEnabled` property to know if you can reply to an event

### Fixed
- Fix event URL validation and check if hostname is correct before showing it
- Fix participations stats on the MyEvents page
- Fix event description lists margin
- Clear errors on resend password page (Léo Mouyna)
- End datetime being able to happen before begin datetime (Léo Mouyna)
- Fix issue when activating/deactivating limited places (Léo Mouyna)
- Fix Cypress tests
- Fix contribution guide link and improve contribution guide (Joel Takvorian)
- Improve grammar (Damien)
- Fix recursive alias in systemd unit file (Geno)
- Fix multiline display on participants page
- Add polyfill for IntersectionObserver so that it's usable on relatively old browsers
- Fixed crash on Safari on description input by removing `-apple-system` from font-family
- Improve installation docs (mkljczk)
- Fixed links to contributing and docs (Alex Addams)
- Limit file uploads to 10MB
- Added missing `setup_db.psql` file (Geno)
- Fixed docker setup when using non-GNU make (JohanBaskovec)
- Fixed actors deletion that didn't cascade to followers
- Reduced datetime picker input width
- Clear ActivityPub cache when content is updated or deleted
- Fix HTTP signatures not checked for relay inbox
- Handle actor or object being AP Public string (for Mastodon relay subscriptions)
- Fixed Mastodon relay instances subscriptions being shown as users
- Fixed an issue when accessing "My Account"
- Fixed pagination for followers/followings page
- Fixed event HTML representation when `GET` request has no `Accept` header

### Security
- Sanitize event title to avoid XSS

## [1.0.0-beta.1] - 2019-10-15
### Added
- Initial release
