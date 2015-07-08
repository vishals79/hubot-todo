# Description:
#   Simple todo app
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#    do (task-description): A task will be added with task description and default date (current date) and time (mid-night) values.
#    modify (task-number) with (task-description): A task will be added with task description and default date (current date) and time (mid-night) values.
#    set time (time in the format hh:mm) for (task number): Modify the time for the mentioned task.
#    set date (date in the format DD-MM-YYYY) for (task number): Modify the date for the mentioned task.
#    add note (note-description) for (task number): add note for the mentioned task.
#    remove (task number): remove the mentioned task and all its child tasks and modify the parent task accordingly.
#    list: display the list of tasks on chronological basis.
#    finish (task-number): mark the specified task as complete. In case, task number is not specified, last added task will be marked complete.
#    subtask (description) child of (parent-task-number): add sub task for parent-task-number.
#
# Author:
#   vishal singh

class Todos
	constructor: (@robot) ->
		@robot.brain.data.todos = {}

		@robot.respond /do (.*)/i, @addItem
		@robot.respond /remove ([0-9]+|all)/i, @removeItem
		@robot.respond /list/i, @listItems
		@robot.respond /todo help/i, @help
		@robot.respond /modify ([0-9]+) (.*)/i, @updateItem
		@robot.respond /set time ([0-9]{2}):([0-9]{2}) for ([0-9]+)/i, @setTime
		@robot.respond /set date (([0-9]{2})-([0-9]{2})-([0-9]{4})) for ([0-9]+)/i, @setDate
		@robot.respond /set date today for ([0-9]+)/i, @setTodayDate
		@robot.respond /set date today\+([0-9]+) for ([0-9]+)/i, @setDateWithExpression
		@robot.respond /note (.*) for ([0-9]+)/i, @addNote
		@robot.respond /subtask (.*) for ([0-9]+)/i, @addSubtask
		@robot.respond /finish ([0-9]+)/i, @markTaskAsFinish
		@robot.respond /set default date (([0-9]{2})-([0-9]{2})-([0-9]{4}))/i, @setDefaultDate
		@robot.respond /set default date today\+([0-9]+)/i, @setDefaultDateExpression
		@robot.respond /default date is today/i, @setDefaultTodayDate
		@robot.respond /set default time ([0-9]{2}):([0-9]{2})/i, @setDefaultTime
		@robot.respond /show ([0-9]+)/i, @showTask

	help: (msg) =>
		message = "* do (task-description): A task will be added with task description and default date (current date) and time values.
   	    \n* modify (task-number) with (task-description): update the description of the mentioned task-number.
        \n* set time (time in the format hh:mm) for (task number): Modify the time for the mentioned task.
        \n* set date (date in the format DD-MM-YYYY) for (task number): Modify the date for the mentioned task.
        \n* set date today+n for (task number): Modify the date to be current day + n number of days for the mentioned task.
        \n* set date today for (task number): Modify the date to be current day for the mentioned task.
        \n* note (note-description) for (task number): add note for the mentioned task.
        \n* remove (task number): remove the mentioned task and all its child tasks and modify the parent task accordingly.
        \n* list: display the list of tasks on chronological basis.
        \n* finish (task-number): mark the specified task as complete. In case, task number is not specified, last added task will be marked complete.
        \n* subtask (description) child of (parent-task-number): add sub task for parent-task-number.
        \n* set default time HH:MM : set the HH:MM as default time.
        \n* set default date today+n: set the default date to current date+n
        \n* default date is today: set the current date as default date
        \n* show (task number): show details of the task
        \n* set default date <DD-MM-YYYY>: set the default date to specified DD-MM-YYYY"

		msg.send message

	showTask: (msg) =>
		user 	   = msg.message.user
		task_number = msg.match[1]

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
			desc = task["description"]
			date_str = task["date_str"]
			time = task["time"]
			if task["note"]?
				note = task["note"]
			else
				note = ""
			if task["status"]?
				status = "Complete"
			else
				status = "Incomplete"
			message = "Task Number\n#{task_number}\n\nDescription\n#{desc}\n\nDate\n#{date_str} #{time}\n\nStatus\n#{status}\n\nNote\n#{note}"

		msg.send message

	setTodayDate: (msg) =>

		user 	   = msg.message.user
		task_number= msg.match[1]

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
			task_date = new Date()
			task_date = new Date(task_date.getFullYear(),task_date.getMonth(),task_date.getDate())
			year = task_date.getFullYear()
			month = task_date.getMonth()
			date = task_date.getDate()

			date_str = date+"-"+month+"-"+year

			hour = "00"
			minute = "00"

			task.date_str = date_str
			task.task_date = task_date
			task.time = hour+":"+minute

			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Item updated."
		msg.send message

	setDefaultTime: (msg) =>
		user 	   = msg.message.user
		user_id = user.id
		default_time_key = user_id+"_"+"default_time_key"
		hour = msg.match[1]
		minutes = msg.match[2]

		time_str = hour+":"+minutes

		@robot.brain.data.todos[default_time_key] = []
		@robot.brain.data.todos[default_time_key].push(time_str)

		message = "Default time set to #{time_str}"
		msg.send message

	setDefaultDate: (msg) =>
		user 	   = msg.message.user
		user_id = user.id
		default_date_key = user_id+"_"+"default_date_key"
		date = msg.match[2]
		month = msg.match[3]
		year = msg.match[4]

		task_date = new Date(year,month,date)

		date_str = date+"-"+month+"-"+year

		@robot.brain.data.todos[default_date_key] = []
		@robot.brain.data.todos[default_date_key].push(date_str)
		@robot.brain.data.todos[default_date_key].push(task_date)

		message = "Default date set to #{date_str}"
		msg.send message

	setDefaultDateExpression: (msg) =>
		user 	   = msg.message.user
		user_id = user.id
		default_date_key = user_id+"_"+"default_date_key"
		value = msg.match[1]

		task_date = new Date()
		task_date.setDate(task_date.getDate()+parseInt(value))
		year = task_date.getFullYear()
		month = task_date.getMonth()
		date = task_date.getDate()

		date_str = date+"-"+month+"-"+year

		@robot.brain.data.todos[default_date_key] = []
		@robot.brain.data.todos[default_date_key].push(date_str)
		@robot.brain.data.todos[default_date_key].push(task_date)

		message = "Default date set to #{date_str}"
		msg.send message

	setDefaultTodayDate: (msg) =>
		user 	   = msg.message.user
		user_id = user.id
		default_date_key = user_id+"_"+"default_date_key"

		task_date = new Date()
		year = task_date.getFullYear()
		month = task_date.getMonth()
		date = task_date.getDate()

		date_str = date+"-"+month+"-"+year

		@robot.brain.data.todos[default_date_key] = []
		@robot.brain.data.todos[default_date_key].push(date_str)
		@robot.brain.data.todos[default_date_key].push(task_date)

		message = "Default date set to #{date_str}"
		msg.send message

	setDateWithExpression: (msg) =>
		
		user 	   = msg.message.user
		value = msg.match[1]
		task_number= msg.match[2]

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
			task_date = new Date()
			task_date = new Date(task_date.getFullYear(),task_date.getMonth(),task_date.getDate())
			task_date.setDate(task_date.getDate()+parseInt(value))
			year = task_date.getFullYear()
			month = task_date.getMonth()
			date = task_date.getDate()

			date_str = date+"-"+month+"-"+year

			hour = "00"
			minute = "00"

			task.date_str = date_str
			task.task_date = task_date
			task.time = hour+":"+minute

			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Item updated."
		msg.send message

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
			item.status = "C"
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
		date= msg.match[2]
		month = msg.match[3]
		year = msg.match[4]
		task_number = msg.match[5]

		items      = @getItems(user)
		totalItems = items.length

		if task_number > totalItems
			if totalItems > 0
				message = "That item doesn't exist. #{totalItems} #{date} #{month} #{year} #{task_number}"
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

		if @robot.brain.data.todos[user.id+"_"+"default_date_key"]?
			date_str = @robot.brain.data.todos[user.id+"_"+"default_date_key"][0]
			task_date = @robot.brain.data.todos[user.id+"_"+"default_date_key"][1]
		else
			task_date = new Date()
			task_date = new Date(task_date.getFullYear(),task_date.getMonth(),task_date.getDate())
			year = task_date.getFullYear()
			month = task_date.getMonth()
			date = task_date.getDate()
			date_str = date+"-"+month+"-"+year

		if @robot.brain.data.todos[user.id+"_"+"default_time_key"]?
			time_str = @robot.brain.data.todos[user.id+"_"+"default_time_key"][0]
		else
			time_str = "00:00"

		tasks.date_str = date_str
		tasks.task_date = task_date
		tasks.time = time_str
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
			doesTimeExist = @doesTimeExist(desc)
			if doesTimeExist > 0
				hour = desc.slice(doesTimeExist+1,doesTimeExist+3)
				minutes = desc.slice(doesTimeExist+4,doesTimeExist+6)
				task.time = hour+":"+minutes
				task.description = desc.slice(0,doesTimeExist)
			else
				task.description = desc
			@robot.brain.data.todos[user.id].splice(item - 1, 1,task)

		message = "Item updated."
		msg.send message

	doesTimeExist: (desc) =>
		if desc?
			return desc.indexOf("@")
		else
			return -1

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

				values = @getTaskString(todo,index+1)

				if values.length > 0
					subtasks = todo["subtask_list"]

					for subtask,index in subtasks
						values.push("\n           "+(index+1)+". "+subtask)

					date = new Date(todo["task_date"])
					if date < current_date
						overdue.push(values.join("     "))

					else if date.getMonth() == current_date.getMonth() and date.getDate() == current_date.getDate() and date.getFullYear() == current_date.getFullYear()
						today.push(values.join("     "))

					else if date.getMonth() == next_date.getMonth() and date.getDate() == next_date.getDate() and date.getFullYear() == next_date.getFullYear()
						tomorrow.push(values.join("     "))

					else
						someOtherDay.push(values.join("     "))

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

	getTaskString: (msg,index) =>
		if msg?
			task_string = []
			desc_length = 0
			note_length = 0
			empty_date = " "
			empty_status = " "
			empty_desc = " "
			empty_note = " "
			if msg["description"]?
				desc_length = msg["description"].length
			if desc_length > 0
				if msg["note"]?
					note_length = 0
				task_string.push(index+".  ")
				desc_str = msg["description"]
				desc_start_index = 0
				node_start_index = 0
				if desc_length < 25
					padding_desc = 25-desc_length
					while padding_desc > 0
						desc_str += "  "
						--padding_desc
					task_string.push(desc_str)
					desc_start_index = desc_length
				else	
					task_string.push(msg["description"].substring(desc_start_index,desc_start_index+25))
					desc_start_index = desc_start_index+25
				task_string.push("                 ")
				task_string.push(msg["date_str"]+" "+msg["time"])
				if msg["status"]?
					task_string.push("                 ")
					task_string.push(msg["status"])
				else
					task_string.push(empty_status)
				if note_length > 0	
					if 	note_length < 15
						note_str = msg["note"]
						padding_note = 15-note_length
						while padding_note > 0
						 note_str += "  "
						 --padding_note
						task_string.push(note_str)
						node_start_index = note_length
					else
						task_string.push(msg["note"].substring(node_start_index,node_start_index+15))
						node_start_index = node_start_index+15
				else
					task_string.push(empty_note)

				while desc_start_index < desc_length or node_start_index < note_length
					task_string.push("\n")
					task_string.push("  ")
					if desc_start_index < desc_length
						if (desc_length - desc_start_index) < 25
							desc_str = msg["description"].substring(desc_start_index,desc_length)
							padding_desc = desc_length-desc_start_index
							while padding_desc > 0
							 desc_str += " "
							 --padding_desc
							task_string.push(desc_str)
							desc_start_index = desc_length
						else
							task_string.push(msg["description"].substring(desc_start_index,desc_start_index+25))
							desc_start_index = desc_start_index+25
					else
						task_string.push(empty_desc)

					task_string.push(empty_date)
					task_string.push(empty_status)

					if node_start_index < note_length
						if (note_length - node_start_index) < 15
							note_str = msg["note"].substring(node_start_index,note_length)
							padding_note = note_length-node_start_index
							while padding_note > 0
							 note_str += "   "
							 --padding_note
							task_string.push(note_str)
							node_start_index = note_length
						else
							task_string.push(msg["note"].substring(node_start_index,node_start_index+15))
							node_start_index = node_start_index+15
					else
						task_string.push(empty_note)

			return task_string

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