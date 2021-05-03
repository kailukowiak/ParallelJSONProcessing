echo "Downloading Julia-1.6.1"
wget https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.1-linux-x86_64.tar.gz
echo "Creating directory/apps/julia-1.6.1"
mkdir -p ~/apps/julia-1.6.1
echo "Unpacking"
tar -xzf julia-1.6.1-linux-x86_64.tar.gz -C ~/apps/julia-1.6.1 --strip-components 1
echo "Creating Symlink to Julia"
sudo ln -s ~/apps/julia-1.6.1/bin/julia /usr/local/bin
echo "Cleaning"
rm julia-1.6.1-linux-x86_64.tar.gz
echo "Setting threads"
export JULIA_NUM_THREADS=4
source .bashrc

echo "Downloading files"
git clone git@github.com:kailukowiak/ParallelJSONProcessing.git

echo "Setting up environment"
cd ParallelJSONProcessing
julia -e 'import Pkg; Pkg.activate("."); Pkg.instantiate()'
