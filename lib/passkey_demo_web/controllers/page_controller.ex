defmodule PasskeyDemoWeb.PageController do
  use PasskeyDemoWeb, :controller
  alias PasskeyDemo.User
  alias PasskeyDemoWeb.Token

  def login(conn, %{"token" => token}) do
    case Token.verify(token) do
      {:ok, user_id} ->
        conn
        |> put_session("user", user_id)
        |> redirect(to: ~p"/me")

      _ ->
        put_flash(conn, "error", "invalid token")
    end
  end

  def logout(conn, _) do
    conn
    |> delete_session("user")
    |> redirect(to: ~p"/")
  end

  def me(conn, _params) do
    user_id = get_session(conn, "user")

    case User.get_by_id(user_id) do
      [{id, name, username, _key_id, _public_key}] ->
        user = %{id: id, name: name, username: username}
        render(conn, :me, user: user)

      [] ->
        redirect(conn, to: ~p"/")
    end
  end
end
