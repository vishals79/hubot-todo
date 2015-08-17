# Get started with task management


## How to add taskbot

Click on "Direct Message" to add task bot

![alt text](https://github.com/vishals79/hubot-todo/blob/master/etc/add-bot.jpg "add bot")


## Usage Document

**task_number = last added task, if (task_number) is not provided**

### 1. add|create (task-description) @hh:mm (optional) : To create a new task
	Examples:
	i. add Call John for requirement analysis
	ii. create Call John for requirement analysis
	iii. add Call John for requirement analysis @ 15:30
	iv. create Call John for requirement analysis @ 15:30

### 2. update (task_number) (task-description) @hh:mm (optional): To update the description and time of an existing task.
	Examples:
	i.   update Call John for requirement analysis and timeline discussion
	ii.  update Call John for requirement analysis and timeline discussion @ 18:00
	iii. update 3 Deploy code @20:00

### 3. delete (task_number|all): To delete an existing task.
	Examples:
	i.   delete
	ii.  delete 2
	iii. delete all

First will delete last added task. Second will delete task number 2 and third will delete all tasks.

### 4. show (task_number): To display details of an existing task.
	Examples:
	i. show
	ii. show 3

First will display details of last added task and second will show details of task number 3.

### 5. note (task_number) (note-description): To add note for a task.
	Examples:
	i. note Inform Mark after completing the task.
	ii. note 3 Inform Mark after completing the task.

### 6. complete (task_number): To mark a task as complete.
	Examples:
	i. complete
	ii. complete 3

### 7. time (task_number) (time in the format hh:mm): To change time for a task.
	Examples:
	i. time 10:15
	ii. time 3 10:15

### 8. date (task_number) (date in the format DD-MM-YYYY): To change date for a task.
	Examples:
	i. date 22-08-2015
	ii. date 3 22-08-2015

### 9. date (task_number) today+n: To change date for a task.
	Examples:
	i. date today
	ii. date 3 today+1

### 10. list: To display list of tasks.
	Example:
	i. list

### 11. subtask (description) for (parent-task-number): To add subtask for a task.
	Example:
	i. subtask Send status email after code deployment for 3

### 12. default time HH:MM: To set default time for task creation.
	Example:
	i. default time 22:00

### 13. default date today+n: To set default date for task creation.
	Example:
	i. default date today+1

### 14. default date (DD-MM-YYYY): To set default date for task creation.
	Example:
	i. default date 15-08-2015

### 15. assign (task_number) @User_Id: Assign a task to any other user.
	Examples:
	i. assign @vishal.singh
	ii. assign 3 @vishal.singh

### 16. notifications: To display all notifications (tasks assigned/rejected by users)
	Example:
	i. notifications

### 17. accept (task_number): To accept a task assigned by any user.
	Examples:
	i. accept
	ii. accept 3

### 18. reject (task_number): To reject a task assigned by any user.
	Examples:
	i. reject
	ii. reject 3

### 19. clear: To clear all notifications
	Example:
	i. clear

