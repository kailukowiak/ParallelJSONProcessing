using Distributed
using ClusterManagers
OnCluster = true #set to false if executed on local machine
addWorkers = true
println("OnCluster = $(OnCluster)")

# Current number of workers
#--------------------------
currentWorkers = nworkers()
println("Initial number of workers = $(currentWorkers)")

# I want to have maxNumberWorkers workers running
#-------------------------------------------------
maxNumberWorkers = 4
if addWorkers == true
	if OnCluster == true
	#if using SGE instead of slurm:
	#ClusterManagers.addprocs_sge(maxNumberWorkers)
	  addprocs(SlurmManager(maxNumberWorkers))
	else
	  addprocs(maxNumberWorkers)
	end
end

# Check the distribution of workers across nodes
#-----------------------------------------------
hosts = []
pids = []
for i in workers()
	host, pid = fetch(@spawnat i (gethostname(), getpid()))
	println("Hello I am worker $(i), my host is $(host)")
	push!(hosts, host)
	push!(pids, pid)
end