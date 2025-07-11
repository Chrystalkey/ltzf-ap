defmodule LtzfApWeb.SharedLiveHelpers do
  @moduledoc """
  Shared helper functions for LiveView components.
  """

  @seconds_per_day 86400
  @seconds_per_hour 3600
  @seconds_per_minute 60

  def format_time_remaining(expires_at) do
    case DateTime.from_iso8601(expires_at) do
      {:ok, expires_datetime, _} ->
        now = DateTime.utc_now()
        diff_seconds = DateTime.diff(expires_datetime, now)

        if diff_seconds <= 0 do
          "Expired"
        else
          days = div(diff_seconds, @seconds_per_day)
          remaining_seconds = rem(diff_seconds, @seconds_per_day)
          hours = div(remaining_seconds, @seconds_per_hour)
          remaining_seconds = rem(remaining_seconds, @seconds_per_hour)
          minutes = div(remaining_seconds, @seconds_per_minute)

          cond do
            days > 0 -> "#{days}d #{hours}h #{minutes}m"
            hours > 0 -> "#{hours}h #{minutes}m"
            minutes > 0 -> "#{minutes}m"
            true -> "Less than 1m"
          end
        end
      _ ->
        "Unknown"
    end
  end
end
