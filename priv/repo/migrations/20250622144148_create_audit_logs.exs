defmodule LtzfAdmin.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string
      add :resource_type, :string
      add :resource_id, :string
      add :changes, :map
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:audit_logs, [:user_id])
  end
end
