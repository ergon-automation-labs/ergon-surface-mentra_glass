defmodule ErgonSurfaceHudElixirWeb.TabsLive do
  use ErgonSurfaceHudElixirWeb, :live_view

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       active_tab: :chat,
       messages: [],
       current_message: "",
       loading: false,
       system_status: %{nats: "healthy", db: "healthy"},
       bots: [],
       task_updates: []
     )
     |> subscribe_to_updates()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mobile-container">
      <!-- Tab Navigation -->
      <nav class="tab-navigation">
        <button
          class={"tab-button #{if @active_tab == :dashboard, do: "active"}"}
          phx-click="select_tab"
          phx-value-tab="dashboard"
        >
          📊 Dashboard
        </button>
        <button
          class={"tab-button #{if @active_tab == :chat, do: "active"}"}
          phx-click="select_tab"
          phx-value-tab="chat"
        >
          💬 Chat
        </button>
        <button
          class={"tab-button #{if @active_tab == :control, do: "active"}"}
          phx-click="select_tab"
          phx-value-tab="control"
        >
          ⚙️ Control
        </button>
      </nav>
      
    <!-- Tab Content -->
      <div class="tab-content">
        <%= if @active_tab == :dashboard do %>
          <.dashboard_tab bots={@bots} system_status={@system_status} task_updates={@task_updates} />
        <% end %>

        <%= if @active_tab == :chat do %>
          <.chat_tab
            messages={@messages}
            current_message={@current_message}
            loading={@loading}
          />
        <% end %>

        <%= if @active_tab == :control do %>
          <.control_tab bots={@bots} system_status={@system_status} />
        <% end %>
      </div>

      <style>
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
            "Helvetica Neue", Arial, sans-serif;
          background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
          color: #e2e8f0;
          height: 100vh;
          overflow: hidden;
        }

        .mobile-container {
          width: 100%;
          height: 100vh;
          display: flex;
          flex-direction: column;
          background: #0f172a;
        }

        .tab-navigation {
          display: flex;
          gap: 0;
          background: #1a1f35;
          border-bottom: 1px solid #334155;
          flex-shrink: 0;
        }

        .tab-button {
          flex: 1;
          padding: 12px 8px;
          border: none;
          background: transparent;
          color: #94a3b8;
          font-size: 13px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s;
          border-bottom: 3px solid transparent;
          text-align: center;
        }

        .tab-button:active {
          background: rgba(255, 255, 255, 0.05);
        }

        .tab-button.active {
          color: #3b82f6;
          border-bottom-color: #3b82f6;
        }

        .tab-content {
          flex: 1;
          overflow-y: auto;
          overflow-x: hidden;
          display: flex;
          flex-direction: column;
        }

        /* Scrollbar styling */
        ::-webkit-scrollbar {
          width: 6px;
        }

        ::-webkit-scrollbar-track {
          background: #0f172a;
        }

        ::-webkit-scrollbar-thumb {
          background: #334155;
          border-radius: 3px;
        }

        ::-webkit-scrollbar-thumb:hover {
          background: #475569;
        }
      </style>
    </div>
    """
  end

  attr :bots, :list, required: true
  attr :system_status, :map, required: true
  attr :task_updates, :list, required: true

  defp dashboard_tab(assigns) do
    ~H"""
    <div class="dashboard-panel">
      <div class="panel-section">
        <h2 class="section-title">🔧 System Health</h2>
        <div class="status-grid">
          <%= for {key, status} <- @system_status do %>
            <div class="status-item">
              <div class="status-indicator" style={status_color(status)}></div>
              <span class="status-label">{key}</span>
              <span class="status-value">{status}</span>
            </div>
          <% end %>
        </div>
      </div>

      <div class="panel-section">
        <h2 class="section-title">🤖 Active Bots</h2>
        <div class="bots-list">
          <%= if Enum.empty?(@bots) do %>
            <div class="empty-state">No bots online</div>
          <% else %>
            <%= for bot <- @bots do %>
              <div class="bot-card">
                <div class="bot-name">{bot.name}</div>
                <div class="bot-status">{bot.status}</div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <div class="panel-section">
        <h2 class="section-title">📝 Recent Updates</h2>
        <div class="updates-list">
          <%= if Enum.empty?(@task_updates) do %>
            <div class="empty-state">No recent updates</div>
          <% else %>
            <%= for update <- Enum.reverse(@task_updates) |> Enum.take(5) do %>
              <div class="update-item" style={update_color(update.status)}>
                <div class="update-agent">{update.agent}</div>
                <div class="update-message">{update.message}</div>
                <div class="update-time">{format_time(update.timestamp)}</div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <style>
        .dashboard-panel {
          flex: 1;
          overflow-y: auto;
          padding: 12px;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .panel-section {
          background: #1a1f35;
          border-radius: 8px;
          padding: 12px;
          border: 1px solid #334155;
        }

        .section-title {
          font-size: 14px;
          font-weight: 700;
          color: #e2e8f0;
          margin-bottom: 12px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .status-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 8px;
        }

        .status-item {
          background: #0f172a;
          padding: 8px;
          border-radius: 6px;
          display: flex;
          align-items: center;
          gap: 8px;
          font-size: 12px;
        }

        .status-indicator {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          flex-shrink: 0;
        }

        .status-label {
          color: #94a3b8;
          flex: 1;
        }

        .status-value {
          color: #64748b;
          font-size: 11px;
        }

        .bots-list {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .bot-card {
          background: #0f172a;
          padding: 10px;
          border-radius: 6px;
          border-left: 3px solid #3b82f6;
        }

        .bot-name {
          font-weight: 600;
          color: #e2e8f0;
          font-size: 13px;
        }

        .bot-status {
          font-size: 12px;
          color: #cbd5e1;
          margin-top: 4px;
        }

        .updates-list {
          display: flex;
          flex-direction: column;
          gap: 8px;
        }

        .update-item {
          background: #0f172a;
          padding: 10px;
          border-radius: 6px;
          border-left: 3px solid #3b82f6;
          font-size: 12px;
        }

        .update-agent {
          font-weight: 600;
          color: #e2e8f0;
        }

        .update-message {
          color: #cbd5e1;
          margin-top: 4px;
          line-height: 1.4;
        }

        .update-time {
          color: #64748b;
          font-size: 11px;
          margin-top: 4px;
        }

        .empty-state {
          text-align: center;
          color: #64748b;
          padding: 20px 10px;
          font-size: 13px;
        }
      </style>
    </div>
    """
  end

  attr :messages, :list, required: true
  attr :current_message, :string, required: true
  attr :loading, :boolean, required: true

  defp chat_tab(assigns) do
    ~H"""
    <div class="chat-panel">
      <div class="chat-messages" id="messages" phx-update="stream">
        <%= for {_id, message} <- @messages do %>
          <div class={"message #{message.role}"}>
            <div class="message-bubble">{message.text}</div>
          </div>
        <% end %>
      </div>

      <div class="chat-input-area">
        <input
          id="message-input"
          type="text"
          placeholder="Ask anything..."
          value={@current_message}
          phx-keydown="send_message"
          phx-change="update_message"
          phx-debounce="300"
          autocomplete="off"
        />
        <button phx-click="send_message" disabled={@loading}>
          {if @loading, do: "...", else: "Send"}
        </button>
      </div>

      <style>
        .chat-panel {
          flex: 1;
          display: flex;
          flex-direction: column;
          overflow: hidden;
        }

        .chat-messages {
          flex: 1;
          overflow-y: auto;
          padding: 12px;
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .message {
          display: flex;
          animation: slideIn 0.3s ease-out;
        }

        .message.user {
          justify-content: flex-end;
        }

        .message-bubble {
          max-width: 90%;
          padding: 10px 12px;
          border-radius: 10px;
          word-wrap: break-word;
          font-size: 13px;
          line-height: 1.4;
        }

        .message.user .message-bubble {
          background: #3b82f6;
          color: #fff;
          border-bottom-right-radius: 2px;
        }

        .message.assistant .message-bubble {
          background: #334155;
          color: #e2e8f0;
          border-bottom-left-radius: 2px;
        }

        .chat-input-area {
          padding: 12px;
          border-top: 1px solid #334155;
          background: #0f172a;
          display: flex;
          gap: 8px;
          flex-shrink: 0;
        }

        .chat-input-area input {
          flex: 1;
          padding: 10px 12px;
          border: 1px solid #334155;
          border-radius: 6px;
          background: #1a1f35;
          color: #e2e8f0;
          font-size: 13px;
          outline: none;
          transition: border-color 0.2s;
        }

        .chat-input-area input:focus {
          border-color: #3b82f6;
        }

        .chat-input-area input::placeholder {
          color: #64748b;
        }

        .chat-input-area button {
          padding: 10px 16px;
          background: #3b82f6;
          border: none;
          border-radius: 6px;
          color: #fff;
          font-size: 12px;
          font-weight: 600;
          cursor: pointer;
          transition: background 0.2s;
          flex-shrink: 0;
        }

        .chat-input-area button:active:not(:disabled) {
          background: #2563eb;
        }

        .chat-input-area button:disabled {
          background: #64748b;
          cursor: not-allowed;
          opacity: 0.5;
        }

        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateY(10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      </style>
    </div>
    """
  end

  attr :bots, :list, required: true
  attr :system_status, :map, required: true

  defp control_tab(assigns) do
    ~H"""
    <div class="control-panel">
      <div class="panel-section">
        <h2 class="section-title">⚙️ Bot Control</h2>
        <div class="control-list">
          <%= if Enum.empty?(@bots) do %>
            <div class="empty-state">No bots available</div>
          <% else %>
            <%= for bot <- @bots do %>
              <div class="control-item">
                <div class="control-header">
                  <span class="control-name">{bot.name}</span>
                  <span class="control-status">{bot.status}</span>
                </div>
                <div class="control-actions">
                  <button class="action-btn" phx-click="restart_bot" phx-value-bot={bot.name}>
                    🔄 Restart
                  </button>
                  <button class="action-btn secondary" phx-click="reload_bot" phx-value-bot={bot.name}>
                    ↻ Reload
                  </button>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <div class="panel-section">
        <h2 class="section-title">🎛️ System Controls</h2>
        <div class="system-controls">
          <button class="action-btn large" phx-click="refresh_status">
            🔄 Refresh Status
          </button>
          <button class="action-btn large secondary" phx-click="clear_cache">
            🗑️ Clear Cache
          </button>
        </div>
      </div>

      <style>
        .control-panel {
          flex: 1;
          overflow-y: auto;
          padding: 12px;
          display: flex;
          flex-direction: column;
          gap: 16px;
        }

        .panel-section {
          background: #1a1f35;
          border-radius: 8px;
          padding: 12px;
          border: 1px solid #334155;
        }

        .section-title {
          font-size: 14px;
          font-weight: 700;
          color: #e2e8f0;
          margin-bottom: 12px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .control-list {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .control-item {
          background: #0f172a;
          padding: 12px;
          border-radius: 6px;
          border-left: 3px solid #3b82f6;
        }

        .control-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 8px;
        }

        .control-name {
          font-weight: 600;
          color: #e2e8f0;
          font-size: 13px;
        }

        .control-status {
          font-size: 11px;
          color: #64748b;
          background: rgba(255, 255, 255, 0.05);
          padding: 2px 8px;
          border-radius: 4px;
        }

        .control-actions {
          display: flex;
          gap: 8px;
        }

        .action-btn {
          flex: 1;
          padding: 8px 12px;
          background: #3b82f6;
          border: none;
          border-radius: 6px;
          color: #fff;
          font-size: 12px;
          font-weight: 600;
          cursor: pointer;
          transition: background 0.2s;
          min-height: 36px;
        }

        .action-btn:active {
          background: #2563eb;
        }

        .action-btn.secondary {
          background: #475569;
        }

        .action-btn.secondary:active {
          background: #64748b;
        }

        .action-btn.large {
          width: 100%;
          padding: 12px;
          margin-bottom: 8px;
        }

        .system-controls {
          display: flex;
          flex-direction: column;
        }

        .empty-state {
          text-align: center;
          color: #64748b;
          padding: 20px 10px;
          font-size: 13px;
        }
      </style>
    </div>
    """
  end

  @impl true
  def handle_event("select_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: String.to_atom(tab))}
  end

  def handle_event("update_message", %{"value" => msg}, socket) do
    {:noreply, assign(socket, current_message: msg)}
  end

  def handle_event("send_message", %{"key" => "Enter"}, socket) do
    send_chat_message(socket)
  end

  def handle_event("send_message", _params, socket) do
    send_chat_message(socket)
  end

  def handle_event("refresh_status", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("clear_cache", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("restart_bot", %{"bot" => _bot_name}, socket) do
    {:noreply, socket}
  end

  def handle_event("reload_bot", %{"bot" => _bot_name}, socket) do
    {:noreply, socket}
  end

  defp send_chat_message(%{assigns: %{current_message: "", loading: true}} = socket) do
    {:noreply, socket}
  end

  defp send_chat_message(%{assigns: %{current_message: message}} = socket) when message == "" do
    {:noreply, socket}
  end

  defp send_chat_message(socket) do
    message = socket.assigns.current_message
    user_msg_id = "user_#{System.monotonic_time()}"

    socket =
      socket
      |> assign(loading: true, current_message: "")
      |> stream_insert(:messages, %{id: user_msg_id, role: "user", text: message})

    case ErgonSurfaceHudElixir.NATS.query_bridge(message) do
      {:ok, response} ->
        response_text = response["data"]["response"] || response["response"] || "No response"
        assistant_msg_id = "assistant_#{System.monotonic_time()}"

        {:noreply,
         socket
         |> stream_insert(:messages, %{
           id: assistant_msg_id,
           role: "assistant",
           text: response_text
         })
         |> assign(loading: false)
         |> push_event("scroll_to_bottom", %{})}

      {:error, reason} ->
        error_msg_id = "error_#{System.monotonic_time()}"

        {:noreply,
         socket
         |> stream_insert(:messages, %{
           id: error_msg_id,
           role: "assistant",
           text: "Error: #{reason}"
         })
         |> assign(loading: false)
         |> push_event("scroll_to_bottom", %{})}
    end
  end

  @impl true
  def handle_info({:task_update, update}, socket) do
    {:noreply,
     socket
     |> assign(task_updates: Enum.take([update | socket.assigns.task_updates], 10))}
  end

  defp subscribe_to_updates(socket) do
    if connected?(socket) do
      ErgonSurfaceHudElixir.NATS.subscribe_to_updates(self())
    end

    socket
  end

  defp status_color(status) when status in ["healthy", "ok"] do
    "background: #4ade80;"
  end

  defp status_color(_), do: "background: #64748b;"

  defp update_color(status) when status in ["success", "healthy"] do
    "border-left-color: #4ade80;"
  end

  defp update_color("error"), do: "border-left-color: #ef4444;"
  defp update_color("warning"), do: "border-left-color: #facc15;"
  defp update_color(_), do: "border-left-color: #3b82f6;"

  defp format_time(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%H:%M:%S")
      _ -> timestamp
    end
  end

  defp format_time(_), do: "now"
end
