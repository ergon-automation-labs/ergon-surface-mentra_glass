defmodule ErgonSurfaceMentraGlassElixir.Services.ActivityService do
  require Logger

  @doc "Fetch fitness suggestions from fitness_bot"
  def get_fitness_suggestions do
    case query_nats("fitness.suggestions.get", %{}) do
      {:ok, response} ->
        parse_fitness_response(response)

      {:error, _reason} ->
        default_fitness_suggestions()
    end
  end

  @doc "Fetch chore suggestions from chore_bot"
  def get_chore_suggestions do
    case query_nats("chores.suggestions.get", %{}) do
      {:ok, response} ->
        parse_chore_response(response)

      {:error, _reason} ->
        default_chore_suggestions()
    end
  end

  @doc "Fetch wife care suggestions"
  def get_wife_care_suggestions do
    case query_nats("wife_care.suggestions.get", %{}) do
      {:ok, response} ->
        parse_wife_care_response(response)

      {:error, _reason} ->
        default_wife_care_suggestions()
    end
  end

  @doc "Get current tasks from GTD bot"
  def get_active_tasks do
    case query_nats("gtd.tasks.active", %{}) do
      {:ok, response} ->
        parse_tasks_response(response)

      {:error, _reason} ->
        default_active_tasks()
    end
  end

  defp query_nats(subject, payload) do
    host = System.get_env("NATS_HOST", "localhost")
    port = String.to_integer(System.get_env("NATS_PORT", "4222"))

    try do
      {:ok, nc} = Gnat.start_link(host: host, port: port)

      request_payload = Jason.encode!(payload)

      case Gnat.request(nc, subject, request_payload, timeout: 3000) do
        {:ok, response} ->
          {:ok, Jason.decode!(response.body)}

        {:error, reason} ->
          Logger.error("NATS query error for #{subject}: #{inspect(reason)}")
          {:error, reason}
      end
    rescue
      e ->
        Logger.error("NATS error querying #{subject}: #{inspect(e)}")
        {:error, e}
    end
  end

  defp parse_fitness_response(%{"data" => data}) do
    (data["suggestions"] || [])
    |> Enum.map(&parse_fitness_item/1)
  end

  defp parse_fitness_response(_), do: default_fitness_suggestions()

  defp parse_fitness_item(item) do
    %{
      emoji: item["emoji"] || "💪",
      title: item["exercise"] || item["title"] || "Exercise",
      description: item["details"] || item["description"] || "Complete exercise",
      duration: item["duration"] || 600
    }
  end

  defp parse_chore_response(%{"data" => data}) do
    (data["suggestions"] || [])
    |> Enum.map(&parse_chore_item/1)
  end

  defp parse_chore_response(_), do: default_chore_suggestions()

  defp parse_chore_item(item) do
    %{
      emoji: item["emoji"] || "🧹",
      title: item["chore"] || item["title"] || "Chore",
      description: item["details"] || item["description"] || "Complete chore",
      duration: item["duration"] || 600
    }
  end

  defp parse_wife_care_response(%{"data" => data}) do
    (data["suggestions"] || [])
    |> Enum.map(&parse_wife_care_item/1)
  end

  defp parse_wife_care_response(_), do: default_wife_care_suggestions()

  defp parse_wife_care_item(item) do
    %{
      emoji: item["emoji"] || "👰",
      title: item["activity"] || item["title"] || "Together time",
      description: item["details"] || item["description"] || "Spend quality time",
      duration: item["duration"] || 600
    }
  end

  defp parse_tasks_response(%{"data" => data}) do
    (data["tasks"] || [])
    |> Enum.map(&parse_task_item/1)
    |> Enum.take(3)
  end

  defp parse_tasks_response(_), do: default_active_tasks()

  defp parse_task_item(item) do
    %{
      name: item["title"] || item["name"] || "Untitled task",
      progress: item["progress"] || item["completion"] || 0,
      bots: item["assigned_to"] || item["bots"] || []
    }
  end

  # Default suggestions when bots aren't available
  defp default_fitness_suggestions do
    [
      %{emoji: "💪", title: "Push-ups", description: "3 sets of 15 reps", duration: 600},
      %{emoji: "🏃", title: "Run", description: "3 miles at easy pace", duration: 1200},
      %{emoji: "🚴", title: "Bike", description: "30 min moderate effort", duration: 1800}
    ]
  end

  defp default_chore_suggestions do
    [
      %{emoji: "🧹", title: "Clean desk", description: "Organize workspace", duration: 600},
      %{emoji: "🍽️", title: "Do dishes", description: "Wash and dry", duration: 900},
      %{emoji: "🧺", title: "Laundry", description: "Fold and put away", duration: 1200}
    ]
  end

  defp default_wife_care_suggestions do
    [
      %{emoji: "👰", title: "Plan dinner", description: "Cook together", duration: 1800},
      %{emoji: "💑", title: "Walk together", description: "20 min evening walk", duration: 1200},
      %{emoji: "🎬", title: "Movie night", description: "Watch something fun", duration: 7200}
    ]
  end

  defp default_active_tasks do
    [
      %{name: "Deploy mentra_glass", progress: 85, bots: ["claude_bridge", "gtd_bot"]},
      %{name: "Connect real data", progress: 45, bots: ["llm_bot"]},
      %{name: "System optimization", progress: 20, bots: ["terrain_bot"]}
    ]
  end
end
