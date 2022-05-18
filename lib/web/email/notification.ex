defmodule Mobilizon.Web.Email.Notification do
  @moduledoc """
  Handles emails sent about event notifications.
  """
  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix
  import Mobilizon.Web.Gettext

  alias Mobilizon.Events.{Event, Participant}
  alias Mobilizon.Users.{Setting, User}
  alias Mobilizon.Web.Email
  alias Mobilizon.Web.JsonLD.ObjectView

  @spec before_event_notification(String.t(), Participant.t(), String.t()) ::
          Bamboo.Email.t()
  def before_event_notification(
        email,
        %Participant{event: event, role: :participant} = participant,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Don't forget to go to %{title}",
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participant, participant)
    |> assign(:subject, subject)
    |> assign(:jsonLDMetadata, build_json_ld(participant))
    |> Email.add_event_attachment(event)
    |> render(:before_event_notification)
  end

  @spec on_day_notification(User.t(), list(Participant.t()), pos_integer(), String.t()) ::
          Bamboo.Email.t()
  def on_day_notification(
        %User{email: email, settings: %Setting{timezone: timezone}},
        participations,
        total,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)
    participation = hd(participations)

    subject =
      ngettext("One event planned today", "%{nb_events} events planned today", total,
        nb_events: total
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participation, participation)
    |> assign(:participations, participations)
    |> assign(:total, total)
    |> assign(:timezone, timezone)
    |> assign(:subject, subject)
    |> assign(:jsonLDMetadata, build_json_ld(participations))
    |> render(:on_day_notification)
  end

  @spec weekly_notification(User.t(), list(Participant.t()), pos_integer(), String.t()) ::
          Bamboo.Email.t()
  def weekly_notification(
        %User{email: email, settings: %Setting{timezone: timezone}},
        participations,
        total,
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)
    participation = hd(participations)

    subject =
      ngettext("One event planned this week", "%{nb_events} events planned this week", total,
        nb_events: total
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:participation, participation)
    |> assign(:participations, participations)
    |> assign(:total, total)
    |> assign(:timezone, timezone)
    |> assign(:subject, subject)
    |> assign(:jsonLDMetadata, build_json_ld(participations))
    |> render(:notification_each_week)
  end

  @spec pending_participation_notification(User.t(), Event.t(), pos_integer()) :: Bamboo.Email.t()
  def pending_participation_notification(
        %User{locale: locale, email: email, settings: %Setting{timezone: timezone}},
        %Event{} = event,
        total
      ) do
    Gettext.put_locale(locale)

    subject =
      ngettext(
        "One participation request for event %{title} to process",
        "%{number_participation_requests} participation requests for event %{title} to process",
        total,
        number_participation_requests: total,
        title: event.title
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:event, event)
    |> assign(:total, total)
    |> assign(:timezone, timezone)
    |> assign(:subject, subject)
    |> render(:pending_participation_notification)
  end

  @spec build_json_ld(Participant.t()) :: String.t()
  defp build_json_ld(%Participant{} = participant) do
    "participation.json"
    |> ObjectView.render(%{participant: participant})
    |> Jason.encode!()
  end

  defp build_json_ld(participations) when is_list(participations) do
    participations
    |> Enum.map(&ObjectView.render("participation.json", %{participant: &1}))
    |> Jason.encode!()
  end
end
