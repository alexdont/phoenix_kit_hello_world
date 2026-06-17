defmodule PhoenixKitHelloWorld.Paths do
  @moduledoc """
  Centralized path helpers for the Hello World module.

  All paths go through `PhoenixKit.Utils.Routes.path/1` for prefix/locale handling.

  ## Why centralize paths?

  Never hardcode URLs like `"/admin/hello-world"` in your LiveViews. If the
  parent app changes its PhoenixKit URL prefix (e.g. `/admin` → `/backend`),
  your module breaks. Using `Routes.path/1` through a central `Paths` module
  means one file to update and every navigation automatically follows.
  """

  alias PhoenixKit.Utils.Routes

  @base "/admin/hello-world"

  @doc "Main Hello World landing page with module info and the demo action."
  @spec index() :: String.t()
  def index, do: Routes.path(@base)

  @doc "Activity events feed filtered to this module."
  @spec events() :: String.t()
  def events, do: Routes.path("#{@base}/events")

  @doc "PhoenixKit core component showcase."
  @spec components() :: String.t()
  def components, do: Routes.path("#{@base}/components")

  @doc "Notification system tour (send / customize / manage)."
  @spec notifications() :: String.t()
  def notifications, do: Routes.path("#{@base}/notifications")
end
