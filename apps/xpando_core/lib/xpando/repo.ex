defmodule XPando.Repo do
  use AshPostgres.Repo, otp_app: :xpando_core

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end

  def installed_extensions do
    ["ash-functions", "uuid-ossp", "citext"]
  end
end
