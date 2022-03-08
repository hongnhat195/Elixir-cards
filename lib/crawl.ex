defmodule Crawl do
  def main(input) do
    total_page(input)
    |> fetch_document(input)
    |> encode_json("film")
  end

  def encode_json(input, path) do
    {_status, result} = JSON.encode(input)
    File.write("#{path}.json", result)
  end

  def getTime do
    :calendar.local_time()
  end

  def total_page(response) do
    response1 = Crawly.fetch(response)
    {:ok, document} = Floki.parse_document(response1.body)

    total_page =
      document
      |> Floki.find(".pagination")
      |> Floki.find("li:nth-last-child(2)")
      |> Floki.find("a:first-child")
      |> List.last()
      |> elem(2)
      |> List.last()
      |> String.to_integer()

    total_page
  end

  def fetch_document(total_page, response) do
    list = []

    list1 =
      Stream.map_every(1..total_page, 1, fn x ->
        item = fetch_items("#{response}page/#{x}/")
        [list | item] |> List.delete_at(0)
      end)

    %Crawl.Items{items: list1}
    total = Enum.reduce(list1, 0, fn x, acc -> Enum.count(x) + acc end)
    %Crawl.Items{total: total, items: list1}
  end

  def fetch_items(documentx) do
    response1 = Crawly.fetch(documentx)
    {:ok, document} = Floki.parse_document(response1.body)

    item =
      document
      |> Floki.find(".movie-item")
      |> Enum.map(fn x ->
        %{
          title: Floki.attribute(x, "title") |> Floki.text() |> String.slice(0..-4//1),
          link: Floki.attribute(x, "href") |> Floki.text(),
          thumbnail:
            Floki.find(x, ".public-film-item-thumb")
            |> Floki.attribute("data-bg")
            |> Floki.text()
            |> String.slice(23..-1//1),
          number_of_episode:
            Floki.find(x, ".ribbon")
            |> Floki.text()
            |> String.slice(4..5)
            |> String.replace(" ", ""),
          # |> String.to_integer(),
          # full_series:
          #   Floki.find(x, ".ribbon")
          #   |> Floki.text()
          #   |> String.slice(9..10),
          # # |> String.to_integer(),
          year:
            Floki.find(x, ".movie-title-2")
            |> Floki.text()
            |> String.slice(-5..-2//1)
          # |> String.to_integer()
        }

        # |> Map.to_list()
      end)

    item
  end
end
