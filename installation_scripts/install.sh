clear
echo "--------------------Downloading Redis------------------------------"
wget http://download.redis.io/releases/redis-3.0.2.tar.gz
tar xzf redis-3.0.2.tar.gz
cd redis-3.0.2
echo "--------------------Installing Redis-------------------------------"
make

echo "--------------------Installing hubot-------------------------------"
npm install -g hubot coffee-script yo generator-hubot
cd ..
mkdir taskbot
cd taskbot
yo hubot
