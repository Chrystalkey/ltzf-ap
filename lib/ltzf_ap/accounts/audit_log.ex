defmodule LtzfAp.Accounts.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :string
    field :changes, :map

    belongs_to :user, LtzfAp.Accounts.User

    timestamps()
  end

  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, [:action, :resource_type, :resource_id, :changes, :user_id])
    |> validate_required([:action, :resource_type, :resource_id, :user_id])
    |> validate_inclusion(:action, ["create", "update", "delete", "login", "logout"])
    |> foreign_key_constraint(:user_id)
  end
end
