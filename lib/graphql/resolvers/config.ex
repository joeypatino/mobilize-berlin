defmodule Mobilizon.GraphQL.Resolvers.Config do
  @moduledoc """
  Handles the config-related GraphQL calls.
  """

  alias Mobilizon.Config
  alias Mobilizon.Events.Categories
  alias Mobilizon.Service.FrontEndAnalytics

  @doc """
  Gets config.
  """
  @spec get_config(any(), map(), Absinthe.Resolution.t()) :: {:ok, map()}
  def get_config(_parent, _params, %{context: %{ip: ip}}) do
    geolix = Geolix.lookup(ip)

    country_code =
      case Map.get(geolix, :city) do
        %{country: %{iso_code: country_code}} -> String.downcase(country_code)
        _ -> nil
      end

    location =
      case Map.get(geolix, :city) do
        %{location: %{} = location} -> location
        _ -> nil
      end

    data = Map.merge(config_cache(), %{location: location, country_code: country_code})

    {:ok, data}
  end

  @spec terms(any(), map(), Absinthe.Resolution.t()) :: {:ok, map()}
  def terms(_parent, %{locale: locale}, _resolution) do
    type = Config.instance_terms_type()

    {url, body_html} =
      case type do
        "URL" -> {Config.instance_terms_url(), nil}
        "DEFAULT" -> {nil, Config.generate_terms(locale)}
        _ -> {nil, Config.instance_terms(locale)}
      end

    {:ok, %{body_html: body_html, type: type, url: url}}
  end

  @spec privacy(any(), map(), Absinthe.Resolution.t()) :: {:ok, map()}
  def privacy(_parent, %{locale: locale}, _resolution) do
    type = Config.instance_privacy_type()

    {url, body_html} =
      case type do
        "URL" -> {Config.instance_privacy_url(), nil}
        "DEFAULT" -> {nil, Config.generate_privacy(locale)}
        _ -> {nil, Config.instance_privacy(locale)}
      end

    {:ok, %{body_html: body_html, type: type, url: url}}
  end

  @spec event_categories(any(), map(), Absinthe.Resolution.t()) :: {:ok, [map()]}
  def event_categories(_parent, _args, _resolution) do
    categories =
      Categories.list()
      |> Enum.map(fn %{id: id, label: label} ->
        %{id: id |> to_string |> String.upcase(), label: label}
      end)

    {:ok, categories}
  end

  @spec config_cache :: map()
  defp config_cache do
    case Cachex.fetch(:config, "full_config", fn _key ->
           case build_config_cache() do
             value when not is_nil(value) -> {:commit, value}
             err -> {:ignore, err}
           end
         end) do
      {status, value} when status in [:ok, :commit] -> value
      _err -> %{}
    end
  end

  @spec build_config_cache :: map()
  defp build_config_cache do
    %{
      name: Config.instance_name(),
      registrations_open: Config.instance_registrations_open?(),
      registrations_allowlist: Config.instance_registrations_allowlist?(),
      contact: Config.contact(),
      demo_mode: Config.instance_demo_mode?(),
      description: Config.instance_description(),
      long_description: Config.instance_long_description(),
      slogan: Config.instance_slogan(),
      languages: Config.instance_languages(),
      anonymous: %{
        participation: %{
          allowed: Config.anonymous_participation?(),
          validation: %{
            email: %{
              enabled: Config.anonymous_participation_email_required?(),
              confirmation_required:
                Config.anonymous_event_creation_email_confirmation_required?()
            },
            captcha: %{
              enabled: Config.anonymous_event_creation_email_captcha_required?()
            }
          }
        },
        event_creation: %{
          allowed: Config.anonymous_event_creation?(),
          validation: %{
            email: %{
              enabled: Config.anonymous_event_creation_email_required?(),
              confirmation_required:
                Config.anonymous_event_creation_email_confirmation_required?()
            },
            captcha: %{
              enabled: Config.anonymous_event_creation_email_captcha_required?()
            }
          }
        },
        reports: %{
          allowed: Config.anonymous_reporting?()
        },
        actor_id: Config.anonymous_actor_id()
      },
      geocoding: %{
        provider: Config.instance_geocoding_provider(),
        autocomplete: Config.instance_geocoding_autocomplete()
      },
      maps: %{
        tiles: %{
          endpoint: Config.instance_maps_tiles_endpoint(),
          attribution: Config.instance_maps_tiles_attribution()
        },
        routing: %{
          type: Config.instance_maps_routing_type()
        }
      },
      resource_providers: Config.instance_resource_providers(),
      timezones: Tzdata.zone_list(),
      features: %{
        groups: Config.instance_group_feature_enabled?(),
        event_creation: Config.instance_event_creation_enabled?()
      },
      restrictions: %{
        only_admin_can_create_groups: Config.only_admin_can_create_groups?(),
        only_groups_can_create_events: Config.only_groups_can_create_events?()
      },
      rules: Config.instance_rules(),
      version: Config.instance_version(),
      federating: Config.instance_federating(),
      auth: %{
        ldap: Config.ldap_enabled?(),
        oauth_providers: Config.oauth_consumer_strategies()
      },
      upload_limits: %{
        default: Config.get([:instance, :upload_limit]),
        avatar: Config.get([:instance, :avatar_upload_limit]),
        banner: Config.get([:instance, :banner_upload_limit])
      },
      instance_feeds: %{
        enabled: Config.get([:instance, :enable_instance_feeds])
      },
      web_push: %{
        enabled: !is_nil(Application.get_env(:web_push_encryption, :vapid_details)),
        public_key:
          get_in(Application.get_env(:web_push_encryption, :vapid_details), [:public_key])
      },
      export_formats: Config.instance_export_formats(),
      analytics: FrontEndAnalytics.config()
    }
  end
end
