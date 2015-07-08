# Hubot Todo

A Hubot script that manages TODOs.

## How to install

### Install node.js and npm
	  Follow this link to install node.js and npm - http://joyent.com/blog/installing-node-and-npm

	  Fixing npm permissions (https://docs.npmjs.com/getting-started/fixing-npm-permissions)
	    - mkdir ~/npm-global
	    - npm config set prefix '~/npm-global'
	    - export PATH=~/npm-global/bin:$PATH
	    - source ~/.profile

### Install redis
	  - wget http://download.redis.io/releases/redis-3.0.2.tar.gz
	  - tar xzf redis-3.0.2.tar.gz
	  - cd redis-3.0.2
	  - make
       	  - src/redis-server

### Install Hubot
	  npm install -g hubot coffee-script yo generator-hubot
	  mkdir -p /path/to/hubot
	  cd /path/to/hubot
	  yo hubot
	
       	  For reference follow : https://hubot.github.com/docs/ and https://github.com/slackhq/hubot-slack

### Add hubot slack as dependency 
       	  npm install hubot-slack --save

### Add hubot todo as dependency 
       	  npm install hubot-todo --save

### Add hubot todo to external-scripts.json 
       [
	  "hubot-youtube"
       ] 

## How to run
       - Navigate to /path/to/hubot/
       - HUBOT_SLACK_TOKEN=(API Token) ./bin/hubot -a slack
       	 you can also set HUBOT_SLACK_TOKEN as your environment variable

## Example
### 1. do
	do <task-description>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-do.jpg "do")

### 2. list
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-list.jpg "list")

### 3. modify
	modify <task-number> with <task-description>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-modify.jpg "modify")

### 4. set time
	set time <time in the format hh:mm> for <task number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-settime.jpg "set time")

### 5. set date 
	set date <date in the format DD-MM-YYYY> for <task number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdate.jpg "set date")

### 6. note
	note <note-description> for <task number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-note.jpg "note")

### 7. remove <task number>
	remove <task number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-remove.jpg "remove")

### 8. finish
	finish <task-number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-finish.jpg "finish")

### 9. subtask
	subtask <description> for <parent-task-number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-subtask.jpg "subtask")

### 10. todo help
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-help.jpg "todo help")

## Configuration
See [`src/scripts/todo.coffee`](src/scripts/todo.coffee).

## Work Flow

- Hubot Todo - A todo app to help users in task management. It provides facility to add, update, delete and show tasks.
  - Commands in use
    - Current
      - do (task-description)
        - A task will be added with description and default date (current date) and time (00:00) values.
      - modify (task-number) with (task-description)
        - update the description of the mentioned task-number.
      - set time (time in the format hh:mm) for (task number)
        - Modify the time for the mentioned task.
      - set date (date in the format DD-MM-YYYY) for (task number)
        - Modify the date for the mentioned task.
      - note (note-description) for (task number)
        - add note for the mentioned task.
      - remove (task number)
        - remove the mentioned task and all its subtasks.
      - list
        - display the list of tasks on chronological basis.
      - finish (task-number)
        -  mark the specified task as complete.
      - subtask (description) for (parent-task-number)
        -  add sub task for parent-task-number.
      - set date today/today+n for (task-number)
        - to provide user the feasibility to mark date using text. It will also handle arithmetic expression like today+1/2/3...
      - set default date DD-MM-YYYY|today+n
        - to set default date for task
      - default date is today
        - to set default date for task
      - set default time HH:MM
        - to set default time for task 
      - modify (task-number) with (task-description) @hh:mm 
        - update the task's description. Time is optional(format @hh:mm)
      - show (task number)
        - show details of the task
    - To be added
      - Deploy at Heroku
  - Examples
