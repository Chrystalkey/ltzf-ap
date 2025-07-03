defmodule LtzfApWeb.DateHelpers do
  @moduledoc """
  Helper functions for safely parsing and formatting dates.
  """

  @doc """
  Safely parses an ISO8601 date string and formats it according to the given format.
  Returns the formatted string on success, or the original string on failure.
  """
  def safe_format_datetime(datetime_string, format) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime} ->
        Calendar.strftime(datetime, format)
      {:error, _reason} ->
        # Return the original string if parsing fails
        datetime_string
    end
  end

  def safe_format_datetime(nil, _format), do: nil
  def safe_format_datetime(datetime_string, _format) when not is_binary(datetime_string), do: datetime_string

  @doc """
  Safely parses an ISO8601 date string and formats it as a date (YYYY-MM-DD).
  """
  def safe_format_date(datetime_string) do
    safe_format_datetime(datetime_string, "%Y-%m-%d")
  end

  @doc """
  Safely parses an ISO8601 date string and formats it as a datetime (YYYY-MM-DD HH:MM).
  """
  def safe_format_datetime_short(datetime_string) do
    safe_format_datetime(datetime_string, "%Y-%m-%d %H:%M")
  end

  @doc """
  Safely parses an ISO8601 date string and formats it as a full datetime (YYYY-MM-DD HH:MM:SS).
  """
  def safe_format_datetime_full(datetime_string) do
    safe_format_datetime(datetime_string, "%Y-%m-%d %H:%M:%S")
  end
end
