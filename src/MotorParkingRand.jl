module MotorParkingRand

export main

using JSON
using Debugger
using XLSX
using Random

greet() = print("這是一個用亂數指派機車位給住戶的程式\n")

function julia_main()::Cint
  main()
  return 0
end

function main()
  # data = get_raw()
  # println(data)
  greet()
  execute()
end

# GLOBALS
# Define the mapping from Chinese characters to integers
const CHINESE_NUM_MAP = Dict(
    "一" => 1, "二" => 2, "三" => 3, "四" => 4, "五" => 5, 
    "六" => 6, "七" => 7, "八" => 8, "九" => 9, "十" => 10,
    "十一" => 11, "十二" => 12, "十三" => 13, "十四" => 14, 
    "十五" => 15, "十六" => 16, "十七" => 17, "十八" => 18, 
    "十九" => 19, "二十" => 20, "二十一" => 21, "二十二" => 22, 
    "二十三" => 23, "二十四" => 24, "二十五" => 25, "二十六" => 26, 
    "二十七" => 27, "二十八" => 28, "二十九" => 29, "三十" => 30,
    "三十一" => 31, "三十二" => 32, "三十三" => 33, "三十四" => 34,
    "三十五" => 35, "三十六" => 36, "三十七" => 37, "三十八" => 38,
    "三十九" => 39, "四十" => 40, "四十一" => 41, "四十二" => 42,
    "四十三" => 43, "四十四" => 44, "四十五" => 45, "四十六" => 46,
    "四十七" => 47, "四十八" => 48, "四十九" => 49, "五十" => 50
)

# Function to translate Chinese string to integer
function get_digit_from_chchar(chstr::String)::Int
  return CHINESE_NUM_MAP[chstr]
end

function get_module_path()
  root_path = pwd()
  module_name = MotorParkingRand.get_module_name()
  return joinpath(root_path, module_name)
end

function get_raw()
  root_path = pwd()
  module_name = MotorParkingRand.get_module_name()
  file_path = joinpath(root_path, module_name, "data", "raw.json")

  # Read the file content
  json_string = read(file_path, String)

  # Parse the JSON string into a dictionary
  data_dict = JSON.parse(json_string)
  return data_dict
end

function get_addr(v::Vector{Any})::Vector{String}
  # Validate and extract "a" field
  addrs = [haskey(item, "a") ? item["a"] : "" for item in v]
  filtered_addrs = filter(x -> occursin("１９９巷", x), addrs)

  # Validate that each address ends with "樓" and extract the digit substring
  valid_addrs = String[]
  for (i, addr) in enumerate(filtered_addrs)
      if !endswith(addr, "樓")
          throw(ErrorException("String format must end up with 樓 at index $i"))
      end
      push!(valid_addrs, addr)
  end
  # Debugger.@bp
  # Remove duplicates and process the addresses
  unique_addrs = collect(Set(valid_addrs))
  cleaned_addrs = [occursin("#", x) ? split(x, "#")[2] : x for x in unique_addrs]

  # Sort the addresses by the extracted digit substring
  sorted_addrs = sort(cleaned_addrs) do a, b
      # Extract the substring between "號" and "樓" and convert to integer
      a_num = get_digit_from_chchar(match(r"號(.{1,6})樓", a).captures[1])
      Debugger.@bp
      b_num = get_digit_from_chchar(match(r"號(.{1,6})樓", b).captures[1])
      a_num < b_num
  end

  return sorted_addrs
end

function get_file_path(folder, filename)
  root_path = pwd()
  module_name = MotorParkingRand.get_module_name()
  data_path = joinpath(root_path, module_name, folder)
  # Ensure the directory exists
  if !isdir(data_path)
      mkpath(data_path)
  end

  # Define the file path
  return joinpath(data_path, filename)
end

function save_to_file(strings::Vector{String})
  file_path = get_file_path("data", "results.txt")

  # Open the file in write mode and save the strings
  open(file_path, "w") do file
      for str in strings
          println(file, str)
      end
  end
end

function get_module_name()
  return string(@__MODULE__)
end

function get_tab_from_xlsx(file_path, tab_name)
    # Load the Excel file
    xlsx_file = XLSX.readxlsx(file_path)
    if tab_name in XLSX.sheetnames(xlsx_file)
      return xlsx_file[tab_name]
    else
      error("Sheet $tab_name not found in the workbook.")
    end
end

# Function to convert row and column indices to Excel notation
function excel_cell(row::Int, col::Int)
  col_str = ""
  while col > 0
      col -= 1
      col_str = string(Char(65 + col % 26)) * col_str
      col ÷= 26
  end
  return "$col_str$row"
end

function in_a_check(spot)
  a1 = collect(1:134)
  a2 = collect(218:244)
  a3 = collect(422:486)
  parking_A = vcat(a1,a2,a3)

  return spot in parking_A
end

function in_b_check(spot)
  b1 = collect(135:217)
  b2 = collect(245:421)
  parking_B = vcat(b1,b2)

  return spot in parking_B
end

function get_row_col(str)
  # Define the regular expression pattern
  pattern = r"^[A-Za-z]\d{1,2}-\d{1,2}$"
  col_base = 2
  d_upper_bound = 12
  if occursin(pattern, str)
    h = split(str, "-")
    style = h[1]
    floor = h[2]
    if h[1][1] == 'A'
      nothing
    elseif h[1][1] == 'B'
      col_base = 13
      d_upper_bound = 13
    else
      println("戶別必須是A或者B開頭")
      return 1
    end
    d = parse(Int, h[1][2:end])
    if d == 4
      println("戶別 $style 不存在")
      return 3
    elseif d < 1 || d > d_upper_bound
      println("戶別 $style 不存在")
      return 4
    end
    if d < 4
      col = col_base + d
    else
      col = col_base + d - 1
    end

    # 有幾個戶型沒有二樓
    no_2F = ["A3", "A5", "A10", "A11", "A12"]
    f = parse(Int, floor)
    if f == 2
      if style in no_2F
        println("戶別 $style 沒有二樓")
        return 2
      end
    elseif f < 2 || f > 23
      println("$floor 樓不存在")
      return 5
    end
    row = f + 4
    return row, col
  else
    println("$str does not match the pattern")
  end
end

function prompt_yes_no(prompt_message::String)
  while true
      println(prompt_message, " (yes/no): ")
      user_input = readline()
      user_input_lower = lowercase(user_input)
      
      if user_input_lower == "yes"
          return true
      elseif user_input_lower == "no"
          return false
      else
          println("Invalid input. Please enter 'yes' or 'no'.")
      end
  end
end

function prompt_string(prompt_message::String)
  println(prompt_message)
  user_input = readline()
  return user_input
end

function execute()
  handicapped_map = Dict{Any, Any}()
  no_49 = false
  no_145 = false
  no_167 = false
  if prompt_yes_no("請問有人登記殘障車位嗎")
    ans = prompt_string("請依序輸入登記的互別，用「,」做分隔. 比如A3-16, B9-7")
    ans_m = split(ans, ",")
    ans_m = strip.(ans_m)
    ans_m_a = []
    ans_m_b = []
    for i in eachindex(ans_m)
      if ans_m[i][1] == 'A'
        push!(ans_m_a, ans_m[i])
      elseif ans_m[i][1] == 'B'
        push!(ans_m_b, ans_m[i])
      else
        println("戶別必須是A或者B開頭")
        return 1
      end
    end
    # A區只有一個殘障車位: 49
    # B區有兩個殘障車位: 145, 167
    if length(ans_m_a) >= 1
      shuffle!(ans_m_a)
      handi_a = pop!(ans_m_a)
      handicapped_map[get_row_col(handi_a)] = 49
      no_49 = true
    end
    if length(ans_m_b) >= 1
      shuffle!(ans_m_b)
      handi_b1 = pop!(ans_m_b)
      handicapped_map[get_row_col(handi_b1)] = 145
      no_145 = true
      if !isempty(ans_m_b)
        handi_b2 = pop!(ans_m_b)
        handicapped_map[get_row_col(handi_b2)] = 167
        no_167 = true
      end
    end
  end
  file_path = get_file_path("data", "input.xlsx")
  out_path = get_file_path("data", "output.xlsx")
  sheet = get_tab_from_xlsx(file_path, "motor")
  parking_map = sheet["C6:Z26"]


  # Define parking spots for A
  a1 = collect(1:48)
  ac = 49
  a2 = collect(50:134)
  a3 = collect(218:244)
  a4 = collect(422:486)
  if no_49
    parking_A = vcat(a1,a2,a3,a4)
    lenA = length(parking_A)
    @assert lenA == 225  "Number of parking spaces in A should be 225 instead, $lenA"
  else
    parking_A = vcat(a1,ac,a2,a3,a4)
    lenA = length(parking_A)
    @assert lenA == 226  "Number of parking spaces in A should be 226 instead, $lenA"
  end
  
  

  # Define parking spots for B
  b1 = collect(135:144)
  bc1 = 145
  b2 = collect(146:166)
  bc2 = 167
  b3 = collect(168:217)
  b4 = collect(245:421)
  if no_145 && no_167
    parking_B = vcat(b1,b2,b3,b4)
    lenB = length(parking_B)
    @assert lenB == 258  "Number of parking spaces in B should be 258 instead, $lenB"
  elseif no_145
    parking_B = vcat(b1,b2,bc2,b3,b4)
    lenB = length(parking_B)
    @assert lenB == 259  "Number of parking spaces in B should be 259 instead, $lenB"
  else
    parking_B = vcat(b1,bc1,b2,bc2,b3,b4)
    lenB = length(parking_B)
    @assert lenB == 260  "Number of parking spaces in B should be 260 instead, $lenB"
  end
  


  # Randomize
  shuffle!(parking_A)
  shuffle!(parking_B)

  cp(file_path, out_path; force=true)
  # Create a new Excel file with the same header as the input
  XLSX.openxlsx(out_path, mode="rw") do of
      # Create a new sheet
      st = of["motor"]
      # Fill in the randomized values
      # Specify the starting cell
      start_row = 6  # Starting row index (for C6)
      start_col = 3  # Starting column index (for column C)
      for idx in CartesianIndices(parking_map)
        row, col = Tuple(idx)
        row_shift = row + start_row - 1
        col_shift = col + start_col - 1
        if !isempty(handicapped_map)
          if haskey(handicapped_map, (row_shift, col_shift))
            val = pop!(handicapped_map, (row_shift, col_shift))
            st[row_shift, col_shift] = val
            continue
          end
        end
        if parking_map[row, col] == "a"
          st[row_shift, col_shift] = pop!(parking_A)
        elseif parking_map[row, col] == "b"
          st[row_shift, col_shift] = pop!(parking_B)
        else
          st[row_shift, col_shift] = "x"
        end
      end
  end
  lenA = length(parking_A)
  @assert lenA == 0  "Number of parking spaces left in A should be 0 instead, $lenA"
  lenB = length(parking_B)
  @assert lenB == 0  "Number of parking spaces left in B should be 0 instead, $lenB"
  println("Randomized data has been saved to output.xlsx")
end



end # module MotorParkingRan

