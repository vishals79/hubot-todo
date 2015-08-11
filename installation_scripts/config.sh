echo "------------------Adding dependencies--------------------"
cd taskbot
echo "[
 \"hubot-redis-brain\"
]" > external-scripts.json
npm install hubot-slack --save
npm install hubot-todo --save
