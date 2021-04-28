## Libs
using DataFrames
using JSON
using .Threads
using CSV
using ProgressMeter
using AWSS3
using AWS

## parsing
function json2csv(json_path)
    file = open(json_path) do f
        split(read(f, String), "\n")
    end
    df = DataFrame(first_name=String[], last_name=String[], occupation=String[])

    df_list = Vector{DataFrame}()
    for t = 1:nthreads()
        push!(df_list, copy(df))
    end
    @info "Starting multi thread part..."
    @threads for line ∈ file[1:end - 1]
        @info "thread: $(threadid())"
        json = JSON.parse(line)
        println(json)
        push!(df_list[threadid()], json)
    end

    @info "Starting vcat"
    df = vcat(df_list...)
    csv_name = split(json_path, ".json")[1] * ".csv"
    CSV.write(csv_name, df)
end

json2csv("data/file1.json")
##
file = open("data/file1.json") do f
    split(read(f, String), "\n")
end
df = DataFrame(first_name=String[], last_name=String[], occupation=String[])

df_list = Vector{DataFrame}()
for t = 1:nthreads()
    push!(df_list, copy(df))
end

@threads for line ∈ file[1:end - 1]
    println(JSON.parse(line))
end


@threads for line ∈ file[1:end - 1]
    @info "thread: $(threadid())"
    json = JSON.parse(line)
    println(json)
    push!(df_list[threadid()], json)
end