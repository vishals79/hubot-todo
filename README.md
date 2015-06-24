# Hubot Todo

A Hubot script that manages TODOs.

Functions supported: add,update,delete,show and help.

## Example
### todo add <task>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-add.jpg "todo add")

### todo update <task-number> <modified-task-desc>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-update.jpg "todo update")

### todo delete <task-number>
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-delete.jpg "todo delete")

### todo show
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-show.jpg "todo show")

### todo help
![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/todo-help.jpg "todo help")

## Configuration
See [`src/scripts/todo.coffee`](src/scripts/todo.coffee).

## Work Flow

- Hubot Todo - A todo app to help users in task management. It provides facility to add, update, delete and show tasks.
  - How to install
  - Commands in use
    - Current
      - add
        "Add  a task into the list. e.g. todo add <description>"
      - update
        "Update an existing task. e.g. todo update <task-number>"
      - delete
        "Delete an existing task. e.g. todo delete <task-number>"
      - show
        "Show the list of items."
      - help
        "Display help."
    - To be added
      - add 
        - add name -d desc -t time -c category -p priority -s status
          "This will add a task with name, description, time, category, priority and status.
          Time - Time to complete the task.
          Category - Tasks can be tagged to be of any particular category.
          Priority - Tasks can belong to one of the three categories. High, Medium and Low.
          Status - Complete(C) or Incomplete(I)
          name and desc- mandatory, rest optional"
      
      - add subtask
        - to add a subtask for any task using the <task-id> as the parent id.
	  
      - show
        - show -t <time>
          "Show tasks based on time."
        - show -tg <time>
          "Show tasks having time after <time>."
        - show -tl <time>
          "Show tasks having time before <time>."
        - show today
          "Show today's tasks"
        - show week
          "Show current week's tasks"
        - show month
          "Show current month's tasks"
        - show -c category [-d|-a] (optional)
          "Show tasks based on category.
          -d - descending order. 
          -a - ascending order."
        - show -p priority  [-d|-a] (optional)
          "Show tasks based on priority.
          -d - descending order.
          -a - ascending order."
        - show -s status [-d|-a] (optional)
          "Show tasks based on status.
          -d - descending order.
          -a - ascending order."
      - delete
        - delete <task-number>
          "Delete specified task number."
        - delete -s <status>
          "Delete all tasks with status <status>."
        - delete -p <priority>
          "Delete all tasks with priority <priority>."
        - delete -c <category>
          "Delete all tasks with category <category>."
      - finish
        - finish <task-number>
          "Change the status of <task-number> to C (complete)."
  - Examples


