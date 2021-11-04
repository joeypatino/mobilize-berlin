defmodule Mobilizon.Web.Email.User do
  @moduledoc """
  Handles emails sent to users.
  """

  use Bamboo.Phoenix, view: Mobilizon.Web.EmailView

  import Bamboo.Phoenix

  import Mobilizon.Web.Gettext, only: [gettext: 2]

  alias Mobilizon.{Config, Crypto, Users}
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Email

  require Logger

  @spec confirmation_email(User.t(), String.t()) :: Bamboo.Email.t()
  def confirmation_email(
        %User{email: email, confirmation_token: confirmation_token},
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Instructions to confirm your Mobilizon account on %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:token, confirmation_token)
    |> assign(:subject, subject)
    |> assign(:offer_unsupscription, false)
    |> render(:registration_confirmation)
  end

  @spec reset_password_email(User.t(), String.t()) :: Bamboo.Email.t()
  def reset_password_email(
        %User{email: email, reset_password_token: reset_password_token},
        locale \\ "en"
      ) do
    Gettext.put_locale(locale)

    subject =
      gettext(
        "Instructions to reset your password on %{instance}",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, locale)
    |> assign(:token, reset_password_token)
    |> assign(:subject, subject)
    |> assign(:offer_unsupscription, false)
    |> render(:password_reset)
  end

  @spec check_confirmation_token(String.t()) ::
          {:ok, User.t()} | {:error, :invalid_token | Ecto.Changeset.t()}
  def check_confirmation_token(token) when is_binary(token) do
    case Users.get_user_by_activation_token(token) do
      %User{} = user ->
        case Users.update_user(user, %{
               confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second),
               confirmation_sent_at: nil,
               confirmation_token: nil,
               email: user.unconfirmed_email || user.email
             }) do
          {:ok, %User{} = user} ->
            Logger.info("User #{user.email} has been confirmed")
            {:ok, user}

          {:error, %Ecto.Changeset{} = err} ->
            {:error, err}
        end

      nil ->
        {:error, :invalid_token}
    end
  end

  def resend_confirmation_email(%User{} = user, locale \\ "en") do
    with :ok <- we_can_send_email(user, :confirmation_sent_at),
         {:ok, user} <-
           Users.update_user(user, %{
             "confirmation_sent_at" => DateTime.utc_now() |> DateTime.truncate(:second)
           }),
         %Bamboo.Email{} <- send_confirmation_email(user, locale) do
      Logger.info("Sent confirmation email again to #{user.email}")
      {:ok, user.email}
    end
  end

  @spec send_confirmation_email(User.t(), String.t()) :: Bamboo.Email.t()
  def send_confirmation_email(%User{} = user, locale \\ "en") do
    user
    |> Email.User.confirmation_email(locale)
    |> Email.Mailer.send_email_later()
  end

  @doc """
  Check that the provided token is correct and update provided password
  """
  @spec check_reset_password_token(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :user_not_found | Ecto.Changeset.t()}
  def check_reset_password_token(password, token) do
    case Users.get_user_by_reset_password_token(token) do
      %User{} = user ->
        user
        |> User.password_reset_changeset(%{
          "password" => password,
          "reset_password_sent_at" => nil,
          "reset_password_token" => nil
        })
        |> Repo.update()

      nil ->
        {:error, :user_not_found}
    end
  end

  @doc """
  Send the email reset password, if it's not too soon since the last send
  """
  @spec send_password_reset_email(User.t(), String.t()) :: tuple
  def send_password_reset_email(%User{} = user, locale \\ "en") do
    with :ok <- we_can_send_email(user, :reset_password_sent_at),
         {:ok, %User{} = user_updated} <-
           Repo.update(
             User.send_password_reset_changeset(user, %{
               "reset_password_token" => Crypto.random_string(30),
               "reset_password_sent_at" => DateTime.utc_now() |> DateTime.truncate(:second)
             })
           ),
         %Bamboo.Email{} = mail <-
           user_updated
           |> Email.User.reset_password_email(locale)
           |> Email.Mailer.send_email_later() do
      {:ok, mail}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def send_email_reset_old_email(%User{
        locale: user_locale,
        email: email,
        unconfirmed_email: unconfirmed_email
      }) do
    Gettext.put_locale(user_locale)

    subject =
      gettext(
        "Mobilizon on %{instance}: email changed",
        instance: Config.instance_name()
      )

    Email.base_email(to: email, subject: subject)
    |> assign(:locale, user_locale)
    |> assign(:subject, subject)
    |> assign(:new_email, unconfirmed_email)
    |> assign(:offer_unsupscription, false)
    |> render(:email_changed_old)
  end

  def send_email_reset_new_email(%User{
        locale: user_locale,
        unconfirmed_email: unconfirmed_email,
        confirmation_token: confirmation_token
      }) do
    Gettext.put_locale(user_locale)

    subject =
      gettext(
        "Mobilizon on %{instance}: confirm your email address",
        instance: Config.instance_name()
      )

    Email.base_email(to: unconfirmed_email, subject: subject)
    |> assign(:locale, user_locale)
    |> assign(:subject, subject)
    |> assign(:token, confirmation_token)
    |> assign(:offer_unsupscription, false)
    |> render(:email_changed_new)
  end

  @spec we_can_send_email(User.t(), atom) :: :ok | {:error, :email_too_soon}
  defp we_can_send_email(%User{} = user, key) do
    case Map.get(user, key) do
      nil ->
        :ok

      _ ->
        case DateTime.compare(
               DateTime.add(Map.get(user, key), 3600),
               DateTime.utc_now() |> DateTime.truncate(:second)
             ) do
          :lt ->
            :ok

          _ ->
            {:error, :email_too_soon}
        end
    end
  end
end
