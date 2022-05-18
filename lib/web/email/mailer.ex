defmodule Mobilizon.Web.Email.Mailer do
  @moduledoc """
  Mobilizon Mailer.
  """
  use Bamboo.Mailer, otp_app: :mobilizon
  alias Mobilizon.Service.ErrorReporting.Sentry

  @spec send_email_later(Bamboo.Email.t()) :: Bamboo.Email.t()
  def send_email_later(email) do
    Mobilizon.Web.Email.Mailer.deliver_later!(email)
  rescue
    error ->
      Sentry.capture_exception(error,
        stacktrace: __STACKTRACE__,
        extra: %{extra: "Error while sending email"}
      )

      reraise error, __STACKTRACE__
  end

  @spec send_email(Bamboo.Email.t()) :: Bamboo.Email.t() | {Bamboo.Email.t(), any()}
  def send_email(email) do
    Mobilizon.Web.Email.Mailer.deliver_now!(email)
  rescue
    error ->
      Sentry.capture_exception(error,
        stacktrace: __STACKTRACE__,
        extra: %{extra: "Error while sending email"}
      )

      reraise error, __STACKTRACE__
  end
end
