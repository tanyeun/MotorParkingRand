module MotorParkingRand

using JSON
using Debugger

greet() = print("這是一個用亂數指派機車位給住戶的程式")

function main()
  println(data_dict)
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
  Debugger.@bp
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

function save_to_file(strings::Vector{String})
  data_path = joinpath(root_path, module_name, "data")
  # Ensure the directory exists
  if !isdir(data_path)
      mkpath(data_path)
  end

  # Define the file path
  file_path = joinpath(data_path, "results.txt")

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





end # module MotorParkingRan