cd build

cmake ..

make -j $(nproc)

cd ../tools

python3 dbtool.py update

cd ..

screen -d -m -S xi_connect ./xi_connect

screen -d -m -S xi_search ./xi_search

screen -d -m -S xi_map ./xi_map

screen -d -m -S xi_world ./xi_world
