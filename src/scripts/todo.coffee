# Description:
#   Simple todo app
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#    - do (task-description): A task will be added with task description and default date (current date) and time (mid-night) values.
#    - modify (task-number) with (task-description): A task will be added with task description and default date (current date) and time (mid-night) values.
#    - set time (time in the format hh:mm) for (task number): Modify the time for the mentioned task.
#    - set date (date in the format DD-MM-YYYY) for (task number): Modify the date for the mentioned task.
#    - add note (note-description) for (task number): add note for the mentioned task.
#    - remove (task number): remove the mentioned task and all its child tasks and modify the parent task accordingly.
#    - list: display the list of tasks on chronological basis.
#    - finish (task-number): mark the specified task as complete. In case, task number is not specified, last added task will be marked complete.
#    - subtask (description) child of (parent-task-number): add sub task for parent-task-number.
#
# Author:
#   vishal singh

class Todos
	constructor: (@robot) ->
		@robot.brain.data.todos = {}

		@robot.respond /do (.*)/i, @addItem
		@robot.respond /remove ([0-9]+|all)/i, @removeItem
		@robot.respond /list/i, @listItems
		@robot.respond /help/i, @help
		@robot.respond /modify ([0-9]+) (.*)/i, @updateItem
		@robot.respond /set time ([0-9]{2}):([0-9]{2}) for ([0-9]+)/i, @setTime
		@robot.respond /set date ([0-9]{2})-([0-9]{2})-([0-9]{4}) for ([0-9]+)/i, @setDate
		@robot.respond /note (.*) for ([0-9]+)/i, @addNote
		@robot.respond /subtask (.*) for ([0-9]+)/i, @addSubtask
		@robot.respond /finish ([0-9]+)/i, @markTaskAsFinish

	help: (msg) =>
		commands = @robot.helpCommands()
		commands = (command for command in commands when command.match(/( - )/))

		msg.send commands.join("\n")

	markTaskAsFinish: (msg) =>
		user 	   = msg.message.user
		task_number = msg.match[1]

		items      = @getItems(user)
		totalItems = items.length

		if task_number > totalItems
			if totalItems > 0
				message = "Task doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			item = items[task_number-1]
			item.status = "Done"
			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,item)

		message = "Task status updated."
		msg.send message

	addSubtask: (msg) =>
		user 	   = msg.message.user
		description = msg.match[1]
		task_parent_number = msg.match[2]

		items      = @getItems(user)
		totalItems = items.length

		if task_parent_number > totalItems
			if totalItems > 0
				message = "Parent task doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			item = items[task_parent_number-1]
			subtask_list = item.subtask_list
			subtask_list.push(description)
			item.subtask_list = subtask_list

			@robot.brain.data.todos[user.id].splice(task_parent_number - 1, 1,item)

		message = "Sub task added."
		msg.send message

	addChild: (msg) =>
		user 	   = msg.message.user
		task_child_number= msg.match[1]
		task_parent_number = msg.match[2]

		items      = @getItems(user)
		totalItems = items.length

		if task_child_number > totalItems
			if totalItems > 0
				message = "Child task doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else if task_parent_number > totalItems
			if totalItems > 0
				message = "Parent task doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			child_task = items[task_child_number-1]
			parent_task = items[task_parent_number-1]

			parent_task.child = task_child_number
			parent_list = child_task.parents
			parent_list.push(task_parent_number)
			child_task.parents = parent_list

			@robot.brain.data.todos[user.id].splice(task_child_number - 1, 1,child_task)
			@robot.brain.data.todos[user.id].splice(task_parent_number - 1, 1,parent_task)

		message = "Task marked as a child."
		msg.send message


	addNote: (msg) =>
		user 	   = msg.message.user
		note       = msg.match[1]
		task_number = msg.match[2]

		items      = @getItems(user)
		totalItems = items.length

		


		if task_number > totalItems
			if totalItems > 0
				message = "That item doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			task = items[task_number-1]
			task.note = note

			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Note added."
		msg.send message

	setDate: (msg) =>
		user 	   = msg.message.user
		date= msg.match[1]
		month = msg.match[2]
		year = msg.match[3]
		task_number = msg.match[4]

		items      = @getItems(user)
		totalItems = items.length

		


		if task_number > totalItems
			if totalItems > 0
				message = "That item doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			task = items[task_number-1]
			task_date = new Date(year,month,date)

			date_str = date+"-"+month+"-"+year
			task.date_str = date_str
			task.task_date = task_date

			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Item updated."
		msg.send message

	setTime: (msg) =>
		user 	   = msg.message.user
		task_hour= msg.match[1]
		task_minute = msg.match[2]
		task_number = msg.match[3]

		items      = @getItems(user)
		totalItems = items.length

		


		if task_number > totalItems
			if totalItems > 0
				message = "That item doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			task = items[task_number-1]
			task.time = task_hour+":"+task_minute
			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Item updated."
		msg.send message

	addItem: (msg) =>
		user 	   = msg.message.user
		task_desc = msg.match[1]

		tasks = {description:task_desc}

		task_date = new Date()
		task_date = new Date(task_date.getFullYear(),task_date.getMonth(),task_date.getDate())
		year = task_date.getFullYear()
		month = task_date.getMonth()
		date = task_date.getDate()

		date_str = date+"-"+month+"-"+year

		hour = "00"
		minute = "00"

		tasks.date_str = date_str
		tasks.task_date = task_date
		tasks.time = hour+":"+minute
		tasks.child = ""
		tasks.parents = []
		tasks.subtask_list = []

		@robot.brain.data.todos[user.id] ?= []
		@robot.brain.data.todos[user.id].push(tasks)

		totalItems = @getItems(user).length
		multiple   = totalItems isnt 1

		message = "#{totalItems} item" + (if multiple then 's' else '') + " in your list\n\n"

		msg.send message

	removeItem: (msg) =>
		user 	  = msg.message.user
		item       = msg.match[1]
		items      = @getItems(user)
		totalItems = items.length

		if totalItems == 0
			message = "There's nothing on your list at the moment"
			msg.send message
			return

		if item isnt 'all' and item > totalItems
			if totalItems > 0
				message = "That item doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return

		if item is 'all'
			@clearAllItems(user)
		else
			@robot.brain.data.todos[user.id].splice(item - 1, 1)

		
		remainingItems = @getItems(user)
		multiple 	  = remainingItems.length isnt 1

		if remainingItems.length > 0
			message = " Item deleted. #{remainingItems.length} item" + (if multiple then 's' else '') + " left.\n\n"
		else
			message = " Item deleted. There's nothing on your list at the moment "

		msg.send message

	updateItem: (msg) =>
		user      = msg.message.user
		item      = msg.match[1]
		desc      = msg.match[2]
		items      = @getItems(user)
		totalItems = items.length

		


		if item > totalItems
			if totalItems > 0
				message = "That item doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			task = items[item-1]
			task.description = desc
			@robot.brain.data.todos[user.id].splice(item - 1, 1,task)

		message = "Item updated."
		msg.send message


	clearAllItems: (user) => @robot.brain.data.todos[user.id].length = 0

	createListMessage: (user) =>
		items = @getItems(user)

		message = ""
		overdue = ["\n   Overdue\n"]
		today = ["\n   Today\n"]
		tomorrow = ["\n   Tomorrow\n"]
		someOtherDay = ["\n   Rest\n"]

		current_date = new Date()
		current_date = new Date(current_date.getFullYear(),current_date.getMonth(),current_date.getDate())

		next_date = new Date()
		next_date = new Date(next_date.getFullYear(),next_date.getMonth(),next_date.getDate()+1)

		if items.length > 0
			message += "                                                                           To Do List              "
			for todo, index in items
				values = []
				values.push(index + 1)
				values.push(todo["description"])
				values.push(todo["date_str"])
				values.push(todo["time"])
				values.push(todo["note"])
				values.push(todo["status"])

				subtasks = todo["subtask_list"]

				for subtask,index in subtasks
					values.push("\n           "+(index+1)+". "+subtask)

				date = new Date(todo["task_date"])
				if date < current_date
					overdue.push(values.join("                "))

				else if date.getMonth() == current_date.getMonth() and date.getDate() == current_date.getDate() and date.getFullYear() == current_date.getFullYear()
					today.push(values.join("                "))

				else if date.getMonth() == next_date.getMonth() and date.getDate() == next_date.getDate() and date.getFullYear() == next_date.getFullYear()
					tomorrow.push(values.join("                "))

				else
					someOtherDay.push(values.join("                "))

			if overdue.length > 1
				message += overdue.join("\n")
				message += "\n-------------------------------------------------------------------------------------------------------------\n"
			if today.length > 1
				message += today.join("\n")
				message += 
				"\n-------------------------------------------------------------------------------------------------------------\n"
			if tomorrow.length > 1
				message += tomorrow.join("\n")
				message += 
				"\n-------------------------------------------------------------------------------------------------------------\n"
			if someOtherDay.length > 1
				message += someOtherDay.join("\n")
		else
			message += "Nothing to do at the moment!"

		return message

	getItems: (user) => return @robot.brain.data.todos[user.id] or []

	listItems: (msg) =>
		user   	= msg.message.user
		totalItems = @getItems(user).length
		multiple   = totalItems isnt 1

		message = ""

		if totalItems > 0
			message += "#{totalItems} item" + (if multiple then 's' else '') + " in your list\n\n"

		message += @createListMessage(user)

		msg.send message

module.exports = (robot) -> new Todos(robot)