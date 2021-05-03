## Libs
using Distributed
using ClusterManagers
OnCluster = true # set to false if executed on local machine
addWorkers = true
println("OnCluster = $(OnCluster)")
# s3_read_write_resource = arn:aws:s3:::lukowiak-bucket/*

# Current number of workers
# --------------------------
currentWorkers = nworkers()
println("Initial number of workers = $(currentWorkers)")

# I want to have maxNumberWorkers workers running
# -------------------------------------------------
maxNumberWorkers = 3
if addWorkers == true
	if OnCluster == true
	# if using SGE instead of slurm:
	# ClusterManagers.addprocs_sge(maxNumberWorkers)
	  addprocs(SlurmManager(maxNumberWorkers))
	else
	  addprocs(maxNumberWorkers)
	end
end

@everywhere import Pkg
@everywhere Pkg.activate(".")
@everywhere Pkg.instantiate()
@everywhere begin
    using Revise
    using DataFrames
    using Distributed
    using JSON
    using .Threads
    using CSV
    using ProgressMeter
    using AWSS3
    using AWS
    using FilePathsBase
    using ClusterManagers
end
## AWS Setup
@everywhere aws = global_aws_config(; region="us-east-2")
p = S3Path("s3://lukowiak-bucket/parsedata/",  config=aws)
file_list = readdir(p)
println(file_list)

##
@everywhere function download_execute(s3path)
    filename = split(s3path, "/")[end]
    run(`aws s3 cp $s3path ./tmpdir$(myid())/`)
    json2csv("tmpdir$(myid())/$filename", filename)
    rm("tmpdir$(myid())/$filename")
    
end

# file = joinpath(p, "file1.json")
# s3_get_file(aws, "lukowiak-bucket", "parsedata", "file1.csv")
## parsing
@everywhere function json2csv(json_path, filename)
    file = open(json_path) do f
        split(read(f, String), "\n")
    end
    df = DataFrame(first_name=String[], 
        last_name=String[], 
        occupation=String[], 
        thread_id=Int[])

    df_list = Vector{DataFrame}()
    for t = 1:nthreads()
        push!(df_list, copy(df))
    end
    @threads for line ∈ file[1:end - 1]
    
        json = JSON.parse(line)
        json["thread_id"] = threadid()
        push!(df_list[threadid()], json)
        sleep(5)
    end

    df = vcat(df_list...)
    df[!, :proc_id] .= myid()
    df[!, :computer] .= gethostname()
    csv_name = split(filename, ".json")[1] * ".csv"  # split(json_path, ".json")[1] * ".csv"
    # CSV.write(csv_name, df)
    s3path = S3Path("s3://lukowiak-bucket/parsedata_csv/$csv_name",  config=global_aws_config())
    # s3_put(aws, "lukowiak-bucket", "parsedata/$csv_name", df) 
    CSV.write(s3path, df)
end

# download_execute("s3://lukowiak-bucket/parsedata/file1.json")

# for file ∈ file_list
#     download_execute("s3://lukowiak-bucket/parsedata/$file")
# end

pmap(download_execute, "s3://lukowiak-bucket/parsedata/" .* file_list)