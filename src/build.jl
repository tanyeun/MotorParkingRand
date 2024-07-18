using PackageCompiler
using MotorParkingRand

pkg_path = MotorParkingRand.get_module_path()
println(pkg_path)
bin_path = joinpath(pkg_path, "bin")
println(bin_path)
# Ensure the directory exists
if !isdir(bin_path)
  mkpath(bin_path)
end
# Create the app with the execution file calling the main function
create_app(pkg_path, bin_path; precompile_execution_file="MotorParkingRand/src/run_main.jl", force=true, incremental=true)