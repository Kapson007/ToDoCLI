defmodule ToDoController do
  # ask user for filename
  # open file and read
  # parse the data
  # ask user for command
  # (read, add, delete, load file, save files)

  def start() do
    # IO operation to ask user for filename
    # if no exist then create new file
    # String trim remove white characters in string
    input = IO.gets("Would you like to create a new file? (y/n): ")
            |> String.trim
    # switch case construction to handle user input
    # if user type bad comand then inform him/her and ask again
    case input do
      "y" -> create_initial_Todo() |> getCommand()
      "n" -> load_csv()
      _ -> IO.puts("Unknown command")
           start()
    end
  end

  # function that creats new headers(properties) for todo item
  defp create_headers() do
    # pass empty list and get list of headers
    # defp is private function that is not visible outside of module
    IO.puts("Which headers you want to create for each todo item?\n Enter your headers and add empty line when you finish.\n")
  create_header([])
  end

  # helper function which creats new headers until user type empty line
  defp create_header(headers) do
    # construction [header | headers] add new header to the beginning of the list
    header = IO.gets("Add header: ")
              |> String.trim
    case header do
      "" -> headers
      _ -> create_header([header | headers])
    end
  end

  # function that creates initial todo item when user type yes to create new file
  defp create_initial_Todo() do
    # get list of headers
    titles = create_headers()
    # get map of fields
    name = get_item_name(%{})
    # Enum.map is function that takes list of headers and iterate over it. Callback function returns tuple of key header and value of field
    # &(namefuntion(&1)) is syntax sugar for function that takes one argument and pass it to function - abbreviation for fn x -> namefunction(x) end
    fields = Enum.map(titles, &(getFieldName(&1)))
    # inform that todoItem was created in new todolist
    IO.puts(~s{Todo with name #{name} was added\n})
    # return map of todoitems
    # Enum.into converts list of tuples to map - here its convertion of list of todoitem's fields to map
    %{name => Enum.into(fields, %{})}
  end

  # function that load csv file then parse it and finally return map of todoitems which is pass to function that handle user commands
  # |> is the pipe operator that can handle result of function and pass it to next function
  def load_csv() do
    file = IO.gets("Enter filename: ")
            |> String.trim

    finalPath = "./lib/resources/" <> file <> ".csv"

    read(finalPath)
      |> parseData()
      |> getCommand()
  end

  # function read .csv file and return as string
  # using File module to read file
  #  case is used to handle error if file does not exist, returns tuple of atom error and reason why error is occured
  # then back to startup function
  def read(filename)do
    case File.read(filename) do
      {:ok, data} -> data
      {:error, reason} -> IO.puts ~s(Could not open file: #{filename}\n)
                          IO.puts ~s(Error: #{reason})
                          start()
    end
  end

  # function that parse data as string into map of todoitems
  def parseData(data) do
    # split data by new line character, regex ~r{(\r\n|\r|\n)} is used to split by new line character
    # tl is used to get tail of list - here tail is list of items
    # headers is list of headers from .csv file
    [headers | items] = String.split(data, ~r{(\r\n|\r|\n)})
    # tl operation cut "Items" header
    titles = tl String.split(headers, ",")
    # pass list of headers and list of items to function that parse data
    parse_lines(titles, items)
  end

  # function that parse data into map of todoitems
  defp parse_lines(titles, items) do
    # Enum.reduce is a function that takes list of todoItems, empty map as a starting value and callback function
    # callback function takes line as one element of string and accumulator and return new accumulator
    Enum.reduce(items, %{}, fn line , acc ->
      # get name of todoItem and fields of todoItem with values
      [name | fields] = String.split(line, ",")
      # Enum.zip takes two list and converts into list of tuples then Enum.into converts list of tuples to map
      line_data = Enum.zip(titles, fields) |> Enum.into(%{})
      # in each iteration new map is created with new todoItem and passed to accumulator using Map.merge where name is todoitem name and line_data is map of fields
      Map.merge(acc, %{name => line_data})
    end)
  end

  # function that get parsed todolist and handle user operation in terms of prompt which user chooses
  def getCommand(data) do
    text =
      """
        Please choose command:
        r - read todos
        a - add todo
        d - delete todo
        l - load file
        s - save file
        q - quit
      """
    prompt =
      IO.gets(text)
      |> String.trim

    case prompt do
      "r" -> showTodos(data)
      "a" -> addToDo(data)
      "d" -> deleteTodo(data)
      "l" -> load_csv()
      "s" -> save_csv(data)
      "q" -> IO.puts "Bye!"
      _ ->
        IO.puts("Unknown command")
        getCommand(data)
    end
  end


  # function that get parsed todolist and show it to user
  # after displaying all todos ask user for next command - \\ is used to set default value
  def showTodos(data, next_step \\ true) do

    # get keys which are names of todoitems
    # Enum.count is used to count number of todoitems
    items = Map.keys(data)
    IO.puts "Total number of todos is #{Enum.count(items)}. You have these todos:\n"

    # Enum.each is used to iterate over list of todoitems and print them
    # Enum.each(Map.Keys(data[item]) is used to iterate over fields of todoitem and print them - universal solution for any number of fields
    Enum.each(items, fn item ->
        IO.puts("Item: #{item}\n")
        Enum.each(Map.keys(data[item]), fn key ->
          IO.puts("   - #{key}: #{data[item][key]}\n")
        end)
    end)

    if next_step do
      getCommand(data)
    end
  end


  # function that get parsed todolist and add new todoitem to it
  defp addToDo(data) do
    # get name of todoitem
    name = get_item_name(data)
    # get list of headers
    titles = getField(data)
    # get list of fields, iterate over list of headers and get field name for each header
    fields = Enum.map(titles, fn title -> getFieldName(title) end)
    # create new todoitem with name and fields as map - Enum.into creates map from list of fields, passing empty map as a starting value
    new_todo = %{name => Enum.into(fields, %{})}
    IO.puts(~s{Todo with name "#{name}" was added\n})
    # insert new todoitem into todolist through Map.merge which returns new map - immutable data structure
    new_todo_list = Map.merge(new_todo, data)
    # return new todolist to getCommand handler
    getCommand(new_todo_list)
  end

  # function that get parsed todolist and delete todoitem from it
  def deleteTodo(data) do
    # get name of todoitem and trim whitespaces
    todo_to_delete = IO.gets("Enter todo name You want to delete: ") |> String.trim
    # check if todoitem with name todo_to_delete exists - return boolean
    if Map.has_key?(data, todo_to_delete) do
      IO.puts("Ok")
      # delete todoitem from todolist through Map.drop which returns new map wihout todoitem which should be deleted
      new_list = Map.drop(data, [todo_to_delete])
      IO.puts(~s{Todo with name #{todo_to_delete} was deleted\n})
      # back to user interface
      getCommand(new_list)
    else
      # if element does not exist inform user, show actual list and again ask for todoitem to delete - false oprator is used to display list wihout back to user interface
      IO.puts(~s{Todo with name #{todo_to_delete} does not exist\n})
      showTodos(data, false)
      # call again this function
      deleteTodo(data)
    end
  end

  # function that get name of todoitem, check if exists in list and then return name or call again to get proper name
  def get_item_name(data)do
    name = IO.gets(~s{Enter todo name: })
            |> String.trim
    if( Map.has_key?(data, name) ) do
      IO.puts(~s{Todo with name #{name} already exists\n})
      get_item_name(data)
    end
    name
  end

  # function that get parsed todolist and return list of headers
  defp getField(data) do
    data[hd Map.keys(data)] |> Map.keys
  end

  # function that takes name of field, ask user for value, and return tuple of name of field and value {value, value} - is tuple
  def getFieldName(name) do
    field = IO.gets(~s{Enter #{name} value: })
              |> String.trim
    case field do
      _ -> {name, field}
    end
  end

  # parser of todolist to csv format
  defp parse_todos_to_csv(data) do
    # merge list of headers => Item as name of todo and returned list of fields of each todoitem
    headers = ["Item" | getField(data)]
    # return list of todoitems names
    item_keys = Map.keys(data)
    # Iterate over todoitems names and return list of todo name and list of field as string ex.: ["name", "field1", "field2""]
    item_rows = Enum.map(item_keys, fn item -> [item | Map.values(data[item])] end)
    # merge headers and list of items with fields to one list
    rows = [headers | item_rows]
    # parse this list into strings. Enum.join joins list of strings with comma separator
    parsed_rows = Enum.map(rows, fn row -> Enum.join(row, ",") end)
    # join list of strings into one big string where value are separated with \n
    Enum.join(parsed_rows, "\n")
  end

  # function that takes todolist and save into .csv file - file name is given by user
  defp save_csv(data) do
    # get parsed todolist into string
    result = parse_todos_to_csv(data)
    # get name of file from user and trim whitespaces
    filename = IO.gets("Enter filename: ")
                |> String.trim
    finalPath = "./lib/resources/" <> filename <> ".csv"
    # using case save into file - function write takes filename path and data to save and returns atom :ok if saving has ended successfully or {:error, reason} when something went wrong
    # if wrong then inform user, inject reason of failure and back to user interface
    case File.write(finalPath, result) do
      :ok -> IO.puts("File saved")
            getCommand(data)
      {:error, reason} -> IO.puts("Could not save file: #{reason}\n")
                          IO.puts(~s(#{:file.format_error reason}\n))
                          getCommand(data)
   end
  end
end
