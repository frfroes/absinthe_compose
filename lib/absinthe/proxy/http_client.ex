defmodule Absinthe.Proxy.HTTPClient do
  require Logger

  def resolve(%{url: url} = config, query, variables) do
    headers =
      [
        {"Content-Type", "application/json"},
        {"Accept", "application/graphql"}
      ] ++ Map.get(config, :headers, [])

    body =
      Jason.encode!(%{
        query: query,
        variables: variables
      })

    HTTPoison.post(url, body, headers)
    |> handle_response()
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> Jason.decode()
    |> handle_json()
  end

  def handle_response({:ok, %HTTPoison.Response{status_code: code}}) do
    Logger.error("Non-200 Response from downstream graphql: #{code}")
    {:error, "Unexpected Error"}
  end

  def handle_response({:error, %HTTPoison.Error{} = err}) do
    Logger.error("Downstream error: #{inspect(err)}")
    {:error, "Unexpected Error"}
  end

  def handle_json({:ok, %{"data" => data}}) do
    {:ok, data}
  end

  def handle_json({:ok, other}) do
    Logger.error("Downstream Unexpected JSON Response: #{inspect(other)}")
    {:error, "Unexpected Error"}
  end

  def handle_json({:error, reason}) do
    Logger.error("Downstream JSON Error: #{inspect(reason)}")
    {:error, "Unexpected Error"}
  end
end