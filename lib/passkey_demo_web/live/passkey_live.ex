defmodule PasskeyDemoWeb.PasskeyLive do
  use PasskeyDemoWeb, :live_view
  alias PasskeyDemo.User
  alias PasskeyDemoWeb.Token

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, supported: false, register_disabled: true)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("passkeys-supported", %{"supported" => bool}, socket) do
    socket =
      if bool do
        # put_flash(socket, :info, "passkey supported")
        socket
      else
        put_flash(socket, :error, "passkeys unsupported")
      end
      |> assign(supported: bool)

    {:noreply, socket}
  end

  def handle_event("reg-validate", %{"username" => username}, socket) do
    register_disabled = User.get_by_username(username) |> length() > 0

    socket =
      if register_disabled do
        put_flash(socket, :error, "#user: #{username} already existed")
      else
        socket
      end
      |> assign(register_disabled: register_disabled)

    {:noreply, socket}
  end

  def handle_event("register", %{"username" => username}, socket) do
    attestation = "none"
    origin = socket.endpoint.url()
    rp_id = origin |> URI.parse() |> Map.get(:host)

    id = User.generate_id()
    user = %{id: id, name: username, displayName: username}

    challenge =
      Wax.new_registration_challenge(
        attestation: attestation,
        origin: origin,
        rp_id: rp_id,
        trusted_attestation_types: [:none, :basic]
      )

    challenge_data = %{
      attestation: attestation,
      challenge: Base.encode64(challenge.bytes, padding: false),
      excludeCredentials: [],
      residentKey: :required,
      requireResidentKey: true,
      rp: %{
        id: rp_id,
        name: "Passkey Demo"
      },
      timeout: 60_000,
      user: user
    }

    socket =
      socket
      |> assign(challenge: challenge, user: user)
      |> push_event("registration-challenge", challenge_data)

    {:noreply, socket}
  end

  def handle_event("registration-attestation", payload, socket) do
    %{challenge: challenge, user: user} = socket.assigns

    %{
      "attestation64" => attestation_64,
      "clientData" => client_data,
      "rawId64" => raw_id_64,
      "type" => "public-key"
    } = payload

    attestation = Base.decode64!(attestation_64, padding: false)

    socket =
      case Wax.register(attestation, client_data, challenge) do
        {:ok, {authenticator_data, _result}} ->
          %{attested_credential_data: %{credential_public_key: public_key}} = authenticator_data
          raw_id = Base.decode64!(raw_id_64, padding: false)
          key = %{key_id: raw_id, public_key: public_key}
          :ok = User.register(user, key)
          token = Token.sign(user.id)
          redirect(socket, to: ~p"/login/#{token}")

        {:error, error} ->
          message = Exception.message(error)
          put_flash(socket, :error, message)
      end

    {:noreply, socket}
  end

  def handle_event("authenticate", params, socket) do
    supports_passkey_autofill = Map.has_key?(params, "supports_passkey_autofill")

    event =
      if supports_passkey_autofill,
        do: "authentication-challenge-with-conditional-ui",
        else: "authentication-challenge"

    origin = socket.endpoint.url()
    rp_id = origin |> URI.parse() |> Map.get(:host)

    challenge =
      Wax.new_authentication_challenge(
        origin: origin,
        rp_id: rp_id,
        user_verification: "preferred"
      )

    challenge_data = %{
      challenge: Base.encode64(challenge.bytes, padding: false),
      rpId: challenge.rp_id,
      allowCredentials: challenge.allow_credentials,
      userVerification: challenge.user_verification
    }

    {
      :noreply,
      socket
      |> assign(:challenge, challenge)
      |> push_event(event, challenge_data)
    }
  end

  def handle_event("authentication-attestation", payload, socket) do
    %{
      # "authenticatorData64" => authenticator_data_64,
      # "clientDataArray" => client_data_array,
      "rawId64" => raw_id_64
      # "signature64" => signature_64,
      # "type" => type
    } = payload

    raw_id = Base.decode64!(raw_id_64, padding: false)
    # authenticator_data = Base.decode64!(authenticator_data_64, padding: false)
    # signature = Base.decode64!(signature_64, padding: false)

    # attestation = %{
    #   authenticator_data: authenticator_data,
    #   client_data_array: client_data_array,
    #   raw_id: raw_id,
    #   signature: signature,
    #   type: type
    # }

    [{user_id, _name, _username, _key_id, _public_key}] = User.get_by_key_id(raw_id)
    token = Token.sign(user_id)
    {:noreply, redirect(socket, to: ~p"/login/#{token}")}
  end

  def handle_event("error", %{"message" => _message}, socket) do
    {:noreply, socket}
  end
end
