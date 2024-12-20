defmodule PasskeyDemo.User do
  @moduledoc false
  @table :passkey_demo_user

  def init do
    :dets.open_file(@table, type: :bag)
  end

  def generate_id do
    :crypto.strong_rand_bytes(64)
    |> Base.encode64(padding: false)
  end

  def register(%{id: id, name: name, displayName: username}, %{
        key_id: key_id,
        public_key: public_key
      }) do
    register(id, name, username, key_id, public_key)
  end

  def register(id, name, username, key_id, public_key) do
    :dets.insert(@table, {id, name, username, key_id, public_key})
  end

  def get_by_id(id) do
    :dets.lookup(@table, id)
  end

  def get_by_username(username) do
    :dets.select(@table, [{{:_, :"$1", :_, :_, :_}, [{:==, :"$1", username}], [:"$_"]}])
  end

  def get_by_key_id(key_id) do
    :dets.select(@table, [{{:_, :_, :_, :"$1", :_}, [{:==, :"$1", key_id}], [:"$_"]}])
  end

  def clear_all do
    :dets.delete_all_objects(@table)
  end
end
