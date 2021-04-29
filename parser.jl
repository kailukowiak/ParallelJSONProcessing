## Libs
using Revise
using DataFrames
using JSON
using .Threads
using CSV
using ProgressMeter
using AWSS3
using AWS
using FilePathsBase
using Distributed
## AWS Setup
aws = global_aws_config(; region="us-east-2")
p = S3Path("s3://lukowiak-bucket/parsedata/",  config=global_aws_config())
file_list = readdir(p)
println(file_list)
##
function download_execute(s3path, filename)
    run(`aws s3 cp $s3path ./tmpdir/`)
    json2csv("tmpdir/$filename", filename)
    rm("tmpdir/$filename")
    
end

# file = joinpath(p, "file1.json")
# s3_get_file(aws, "lukowiak-bucket", "parsedata", "file1.csv")
## parsing
function json2csv(json_path, filename)
    file = open(json_path) do f
        split(read(f, String), "\n")
    end
    df = DataFrame(first_name=String[], last_name=String[], occupation=String[])

    df_list = Vector{DataFrame}()
    for t = 1:nthreads()
        push!(df_list, copy(df))
    end
    @threads for line ∈ file[1:end - 1]
    
        json = JSON.parse(line)
        push!(df_list[threadid()], json)
        # sleep(5)
    end

    df = vcat(df_list...)
    csv_name = filename # split(json_path, ".json")[1] * ".csv"
    # CSV.write(csv_name, df)
    s3path = S3Path("s3://lukowiak-bucket/parsedata_csv/$csv_name",  config=global_aws_config())
    # s3_put(aws, "lukowiak-bucket", "parsedata/$csv_name", df)
    CSV.write(s3path, df)
end

for i ∈ 1:length(file_list)
    download_execute("s3://lukowiak-bucket/parsedata/$(file_list[i])", file_list[i])
end

json2csv("data/file1.json")


test = open(file) do s
    data = UInt8[]
    readbytes!(s,data,Inf)
end

s = open(file,"rb")
data = UInt8[]
readbytes!(s,data,Inf)
close(s)
run(`aws s3 cp s3://lukowiak-bucket/parsedata/file3.json .`)