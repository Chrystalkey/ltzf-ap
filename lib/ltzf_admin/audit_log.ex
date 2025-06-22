defmodule LtzfAdmin.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :string
    field :changes, :map
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :resource_type, :resource_id, :changes])
    |> validate_required([:action, :resource_type, :resource_id])
  end
end
