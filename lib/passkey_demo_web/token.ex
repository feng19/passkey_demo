defmodule PasskeyDemoWeb.Token do
  @moduledoc false

  @salt "Passkey user auth"

  def sign(user_id) do
    Phoenix.Token.sign(PasskeyDemoWeb.Endpoint, @salt, user_id) |> Base.url_encode64()
  end

  def verify(token) do
    with {:ok, binary} <- Base.url_decode64(token) do
      Phoenix.Token.verify(PasskeyDemoWeb.Endpoint, @salt, binary, max_age: 86400)
    end
  end
end
