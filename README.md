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
	  "hubot-todo"
       ] 

## How to run
       - Navigate to /path/to/hubot/
       - HUBOT_SLACK_TOKEN=(API Token) ./bin/hubot -a slack
       	 you can also set HUBOT_SLACK_TOKEN as your environment variable

## Example
### 1. add|create
	add|create (task-description)
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-add.jpg "add")

### 2. list
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-list.jpg "list")

### 3. update
	update (task-number) (task-description), task_number = last added task, if task_number is not provided
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-update.jpg "update")

### 4. time
#### time for (task number) (time in the format hh:mm) 
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-settimefortask.jpg "set time for task")

#### time (time in the format hh:mm)
	This will update time of the last added task.
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-settime.jpg "set time")

#### default time (time in the format hh:mm)
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdefaulttime.jpg "set default time")

### 5. date 
#### date for (task number) (date in the format DD-MM-YYYY) 
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdatefortask.jpg "set date for task")

#### date (date in the format DD-MM-YYYY) 
	This will update date of the last added task.
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdate.jpg "set date")

#### date for (task number) today+n
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdatetodayfortask.jpg "set today+n date for task")

#### date today+n
	This will update date of the last added task.
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdatetoday.jpg "set date today+n")

#### default date (date in the format DD-MM-YYYY) 
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdefaultdate.jpg "set default date")

#### default date today+n 
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-setdefaultdatetodayplusn.jpg "set default date today+n")

### 6. note (task number) (note-description)
	note (task number) (note-description), task_number = last added task, if task_number is not provided
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-note.jpg "note")

### 7. delete
	delete (task number)|all, task_number = last added task, if task_number is not provided
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-delete.jpg "delete")

### 8. complete
	complete (task-number), task_number = last added task, if task_number is not provided
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-complete.jpg "complete")

### 9. subtask
	subtask (description) for (parent-task-number)
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-subtask.jpg "subtask")

### 10.show
      	show (task number), task_number = last added task, if task_number is not provided
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-show.jpg "todo show")

### 10. help
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-help.jpg "todo help")

## Configuration
See [`src/scripts/todo.coffee`](src/scripts/todo.coffee).

## Work Flow

- Hubot Todo - A todo app to help users in task management. It provides facility to add, update, delete and show tasks.
  - Commands in use
    - Current
      - add|create (task-description)
        - A task will be added with task description, default date and time.
      - update (task-number) (task-description) ,where task-number is optional
        - It will update the description of the mentioned task-number. If task number is not specified, last added task present in the context 		  gets modified.   
      - delete (task number|all) ,where task-number is optional
        - If task number is not specified, last added task present in the context gets removed. 
      - time (time in the format hh:mm)
        - Modify time of the last added task.
      - date (date in the format DD-MM-YYYY)
        - Modify date of the last added task.
      - date today+n
        - Modify date of the last added task to current day + n number of days.
      - subtask (description) for (parent-task-number)
        - Add sub task for parent-task-number.
      - list
        - display the list of tasks on chronological basis.
      - default time HH:MM
        -  Set HH:MM as default time.
      - default date today+n
        -  Set default date to current date+n
      - show (task number) ,where task-number is optional
        - Show details of the task.
      - note (task number) (note-description) ,where task-number is optional
        - Add note for (task number)
      - complete (task-number) ,where task-number is optional
        - Mark the specified task as complete. In case, task number is not specified, last added task will be marked complete.
      - default date (DD-MM-YYYY)
        - Set default date to (DD-MM-YYYY) 
      - update (task-number) with (task-description) @hh:mm 
        - update the task's description. Time is optional(format @hh:mm)
      - Note: For modifying Time/Date for any particular task, specify (task-number) e.g. time for (task number) (time in the format hh:mm)

    - To be added
      - Modified command sets with new syntax - This will make commands easy to remember. (Present in the latest script)
      - Change in response given by hubot after execution of each commands. (Present in the latest script)
      - Tree structure - Addition of subtask with parent child relationships (Release on 27th July)
      - Undo - To undo the last action (Release on 28th July)
  - Examples
