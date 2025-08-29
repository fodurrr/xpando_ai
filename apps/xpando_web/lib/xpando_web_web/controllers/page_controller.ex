defmodule XpandoWebWeb.PageController do
  use XpandoWebWeb, :controller
  alias XPando.Core
  import Phoenix.Component, only: [to_form: 1]

  def home(conn, _params) do
    # Create an empty form for the newsletter
    form =
      AshPhoenix.Form.for_create(Core.Newsletter, :create, domain: Core, as: "newsletter")
      |> to_form()

    # Use the dedicated home layout
    render(conn, :home, layout: {XpandoWebWeb.Layouts, :home}, form: form)
  end

  def subscribe(conn, %{"newsletter" => newsletter_params}) do
    form = AshPhoenix.Form.for_create(Core.Newsletter, :create, domain: Core, as: "newsletter")

    case AshPhoenix.Form.validate(form, newsletter_params) |> AshPhoenix.Form.submit() do
      {:ok, _subscription} ->
        conn
        |> put_flash(:info, "Successfully subscribed to our newsletter!")
        |> redirect(to: ~p"/")

      {:error, form} ->
        render(conn, :home, layout: {XpandoWebWeb.Layouts, :home}, form: to_form(form))
    end
  end

  def app(conn, _params) do
    render(conn, :app, layout: {XpandoWebWeb.Layouts, :app_page})
  end
end
