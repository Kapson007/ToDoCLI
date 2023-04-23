defmodule MarkupModule do
 def processDataToMarkdown(todoList) do
  parse(todoList) |> saveToMdFile
  # pass parsed todolist to markdown into function that saves in .md file
 end

 defp parse(listToParse) do
  # get todo names
  todosNames = Map.keys(listToParse)
  # parse each todo into map of todos - one string with name and details
  parsedData = Enum.map(todosNames, fn todoName ->
    # parse details into one string with detail name and value
    parsedItem = Enum.join(
      # in map get list of key details using Map.keys(listToParse[todoName])
      Enum.map(Map.keys(listToParse[todoName]), fn detail ->
        # parse into markdown string with newline
        "- #{detail}: #{listToParse[todoName][detail]}" end), "\n")
    "## #{todoName} \n #{parsedItem}\n"
  end)
  # end with horizontal line
  Enum.join(parsedData, "---\n")
 end

  defp saveToMdFile(markdownList) do
    # target path for resources
    basePath = "./lib/resources/markdown/"
    filename = IO.gets("Choose filename: ") |> String.trim
    finalPath = basePath <> filename <> ".md"

    case File.write(finalPath, markdownList) do
      :ok -> IO.puts("List saved in #{finalPath}}")
      {:error, reason} -> IO.puts("Error! #{reason}\n")
    end
  end
end
