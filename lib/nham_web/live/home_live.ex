defmodule NhamWeb.HomeLive do
  use NhamWeb, :live_view

  alias Nham.Posts
  alias Nham.Posts.Post
  alias Phoenix.PubSub

  @impl true
  def render(%{loading: true} = assigns) do
    ~H"""
    <h1 class="text-3xl font-bold underline">Loading...</h1>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl font-bold underline">Nham</h1>
    <.button type="button" phx-click={show_modal("new-post-modal")}>New Post</.button>

    <.modal id="new-post-modal">
      <.simple_form for={@form} phx-submit="save-post" phx-change="validate">
        <h1 class="text-3xl font-bold underline">New Post</h1>
        <.live_file_input upload={@uploads.image} required />
        <.input field={@form[:caption]} type="textarea" label="Caption" />
        <.button type="submit" phx-disable-with="Saving...">Save</.button>
      </.simple_form>
    </.modal>

    <div id="feed" phx-update="stream" class="flex flex-col gap-2">
      <div
        :for={{dom_id, post} <- @streams.posts}
        id={dom_id}
        class="card w-1/2 bg-base-100 shadow flex flex-col gap-2 p-4 border rounded"
      >
        <img src={post.image_path} class="w-full" />
        <p><%= post.user.email %></p>
        <p><%= post.caption %></p>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Nham.PubSub, "posts")

      form =
        %Post{}
        |> Post.changeset(%{})
        |> to_form(as: "post")

      socket =
        socket
        |> assign(form: form, loading: false)
        |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
        |> stream(:posts, Posts.list_posts())

      {:ok, socket}
    else
      {:ok, assign(socket, loading: true)}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save-post", %{"post" => post_params}, socket) do
    %{current_user: user} = socket.assigns

    post_params
    |> Map.put("user_id", user.id)
    |> Map.put("image_path", List.first(consume_files(socket)))
    |> Posts.save()
    |> case do
      {:ok, post} ->
        socket =
          socket
          |> put_flash(:info, "Post created successfully")
          |> push_navigate(to: ~p"/home")

        PubSub.broadcast(Nham.PubSub, "posts", {:new, Map.put(post, :user, user)})

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_info({:new, post}, socket) do
    socket =
      socket
      |> put_flash(:info, "#{post.user.email} created a new post!")
      |> stream_insert(:posts, post, at: 0)

    {:noreply, socket}
  end

  def consume_files(socket) do
    consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
      dest = Path.join([:code.priv_dir(:nham), "static", "uploads", Path.basename(path)])
      File.cp!(path, dest)

      {:postpone, ~p"/uploads/#{Path.basename(dest)}"}
    end)
  end
end
