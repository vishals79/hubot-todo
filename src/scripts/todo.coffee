# Description:
#   Simple todo app
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#
# Author:
#   vishal singh

class Todos
	constructor: (@robot) ->
		@robot.brain.data.todos = {}

		@robot.respond /(add|create) (.*)/i, @addItem
		@robot.respond /delete( [0-9]+| all){0,1}/i, @removeItem
		@robot.respond /list/i, @listItems
		@robot.respond /help/i, @help
		@robot.respond /update ([0-9]+){0,1}(.*)/i, @updateItem
		@robot.respond /time( [0-9]+){0,1}( ([0-9]{2}):([0-9]{2}))/i, @setTime
		@robot.respond /date( [0-9]+){0,1}( ([0-9]{2})-([0-9]{2})-([0-9]{4}))/i, @setDate
		@robot.respond /date( [0-9]+){0,1} today(\+([0-9]+)){0,1}/i, @setDateWithExpression
		@robot.respond /note ([0-9]+){0,1}(.*)/i, @addNote
		@robot.respond /subtask (.*) for ([0-9]+)/i, @addSubtask
		@robot.respond /complete( [0-9]+){0,1}/i, @markTaskAsFinish
		@robot.respond /default date (([0-9]{2})-([0-9]{2})-([0-9]{4}))/i, @setDefaultDate
		@robot.respond /default date today(\+([0-9]+)){0,1}/i, @setDefaultDateExpression
		@robot.respond /default time ([0-9]{2}):([0-9]{2})/i, @setDefaultTime
		@robot.respond /show( [0-9]+){0,1}/i, @showTask

	help: (msg) =>
		message = "\n* add|create <task-description>
   	    \n\n  task_number = last added task, if <task_number> not provided
   	    \n\n* update <task-number> <task-description>
        \n* delete <task number|all>
        \n* show <task number>
        \n* note <task number> <note-description>
        \n* complete <task-number>
        \n* time <task-number> <time in the format hh:mm>
        \n* date <task-number> <date in the format DD-MM-YYYY>
        \n* date <task-number> today+n
        \n* list
        \n* subtask <description> for <parent-task-number>
        \n* default time HH:MM
        \n* default date today+n
        \n* default date <DD-MM-YYYY>"
        
        

		msg.send message

	showTask: (msg) =>
		user 	   = msg.message.user
		task_number = msg.match[1]
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"

		items      = @getItems(user)
		totalItems = items.length

		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context.\nPlease specify the task number to be marked as complete."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to be marked as complete."
				msg.send message
				return


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
			message = "\nTask Number: #{task_number}\n\nDescription:\n#{desc}\n\nDeadline:\nDate: #{date_str}\nTime: #{time}\n\nStatus:\n#{status}\n\nNote:\n#{note}"

		message += "\n\n"
		message += @createListMessage(user)
		msg.send message

	setDefaultTime: (msg) =>
		user 	   = msg.message.user
		user_id = user.id
		default_time_key = user_id+"_"+"default_time_key"
		hour = msg.match[1]
		minutes = msg.match[2]
		isValidTime = @isValidTime(hour,minutes)
		if isValidTime != 1
			msg.send "Opps! It seems time format is not correct.\n Time Format : HH:MM\n00 <= HH <= 23\n00<= MM <=59"
			return

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
		isValidDate = @isValidDate(date,month,year)
		if isValidDate != 1
			msg.send "Opps! It seems time format is not correct.\n Date Format : DD-MM-YYYY\n01 <= DD <= 31\n01<=MM<=11\n2015<=YYYY<=2099"
			return

		task_date = new Date(year,month-1,date)
		date_str = @getDate(date,month,year)

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

		if !value
			value = 0

		task_date = new Date()
		task_date.setDate(task_date.getDate()+parseInt(value))
		year = task_date.getFullYear()
		date = task_date.getDate()

		display_month = ""+(task_date.getMonth()+parseInt(1))
		if display_month.length < 2
			display_month = "0"+display_month
		date_str = @getDate(date,display_month,year)

		@robot.brain.data.todos[default_date_key] = []
		@robot.brain.data.todos[default_date_key].push(date_str)
		@robot.brain.data.todos[default_date_key].push(task_date)

		message = "Default date set to #{date_str}"
		msg.send message

	getDate: (date,month,year) =>
		if date? and month? and year?
			date = date.toString()
			month = month.toString()

			if month == "01"
				month_str = "Jan"
			else if month == "02"
				month_str = "Feb"
			else if month == "03"
				month_str = "Mar"
			else if month == "04"
				month_str = "Apr"
			else if month == "05"
				month_str = "May"
			else if month == "06"
				month_str = "Jun"
			else if month == "07"
				month_str = "Jul"
			else if month == "08"
				month_str = "Aug"
			else if month == "09"
				month_str = "Sep"
			else if month == "10"
				month_str = "Oct"
			else if month == "11"
				month_str = "Nov"
			else if month == "12"
				month_str = "Dec"
			else
				month_str = ""

			if date.length < 2
				date = "0"+date
			date_str = date+" "+month_str+" "+year
			return date_str

		return date_str

	setDateWithExpression: (msg) =>
		
		user 	   = msg.message.user
		value = msg.match[3]
		task_number= msg.match[1]
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"

		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context.\nPlease specify the task number to set date."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to set date."
				msg.send message
				return

		if !value
			value = 0

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
			oldDate = task.date_str
			task_date = new Date()
			task_date.setDate(task_date.getDate()+parseInt(value))
			year = task_date.getFullYear()
			month = ""+(task_date.getMonth()+parseInt(1))
			if month.length < 2
				month = "0"+month
			date = task_date.getDate()

			date_str = @getDate(date,month,year)

			hour = "23"
			minute = "59"

			task.date_str = date_str
			task.task_date = task_date
			task.time = hour+":"+minute

			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Task Number: #{task_number}\n\n Old Date: #{oldDate}\n New Date: #{task.date_str}\n Description: #{task.description}"
		message += "\n\n"
		message += @createListMessage(user)
		msg.send message

	markTaskAsFinish: (msg) =>
		user 	   = msg.message.user
		task_number = msg.match[1]

		items      = @getItems(user)
		totalItems = items.length
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"

		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context.\nPlease specify the task number to be marked as complete."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to be marked as complete."
				msg.send message
				return

		if task_number > totalItems
			if totalItems > 0
				message = "Task doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			item = items[task_number-1]
			item.status = "C  "
			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,item)

		message = "Task status updated.\n\n Task Number: #{task_number}\n Date: #{item.date_str}\n Time: #{item.time}\n Status: Complete\n Description: #{item.description}"
		message += "\n\n"
		message += @createListMessage(user)
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
		message += "\n\n"
		message += @createListMessage(user)
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
		note       = msg.match[2]
		task_number = msg.match[1]

		items      = @getItems(user)
		totalItems = items.length

		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"
		

		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context.\nPlease specify the task number to upadte."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to update."
				msg.send message
				return

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

		message = "Task Number: #{task_number}\n\nNote: #{note}"
		message += "\n\n"
		message += @createListMessage(user)
		msg.send message

	setDate: (msg) =>
		user 	   = msg.message.user
		date= msg.match[3]
		month = msg.match[4]
		year = msg.match[5]
		task_number = msg.match[1]
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"


		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context.\nPlease specify the task number to set date."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to set date."
				msg.send message
				return

		
		isValidDate = @isValidDate(date,month,year)
		if isValidDate != 1
			msg.send "Opps! It seems date format is not correct.\n Date Format : DD-MM-YYYY\n01 <= DD <= 31\n01<=MM<=11\n2015<=YYYY<=2099"
			return

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
			oldDate = task.date_str
			task_date = new Date(year,month-1,date)

			date_str = @getDate(date,month,year)
			task.date_str = date_str
			task.task_date = task_date

			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Task Number: #{task_number}\n\n Old Date: #{oldDate}\n New Date: #{task.date_str}\n Description: #{task.description}"
		message += "\n\n"
		message += @createListMessage(user)
		msg.send message

	isValidDate: (date,month,year) =>
		if date? and month? and year?
		 date_str = date+"-"+month+"-"+year
		 doesMatch = date_str.match /(0[1-9]|[1-2][0-9]|3[0-1])-(0[1-9]|1[0-1])-(201[5-9]|20[2-9][0-9])/
		 if doesMatch?
		   return 1
		 else
		   return -1
		else
		   return -1

	isValidTime: (hh,mm) =>
		if hh? and mm?
		 time_str = hh+":"+mm
		 doesMatch = time_str.match /(0[0-9]|1[0-9]|2[0-3]):(0[0-9]|[1-5][0-9]|60)/
		 if doesMatch?
		   return 1
		 else
		   return -1
		else
		   return -1

	setTime: (msg) =>
		user 	   = msg.message.user
		task_hour= msg.match[3]
		task_minute = msg.match[4]
		task_number = msg.match[1]
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"


		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context.\nPlease specify the task number to set time."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to set time."
				msg.send message
				return

		isValidTime = @isValidTime(task_hour,task_minute)
		if isValidTime != 1
			msg.send "Opps! It seems time format is not correct.\n Time Format : HH:MM\n00 <= HH <= 23\n00<= MM <=59"
			return

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
			oldTime = task.time
			task.time = task_hour+":"+task_minute
			@robot.brain.data.todos[user.id].splice(task_number - 1, 1,task)

		message = "Task Number: #{task_number}\n\n Old time: #{oldTime}\n New Time: #{task.time}\n Description: #{task.description}"
		message += "\n\n"
		message += @createListMessage(user)
		msg.send message

	addItem: (msg) =>
		user 	   = msg.message.user
		task_desc = msg.match[2]
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"

		tasks = {description:task_desc}

		if @robot.brain.data.todos[user.id+"_"+"default_date_key"]?
			date_str = @robot.brain.data.todos[user.id+"_"+"default_date_key"][0]
			task_date = @robot.brain.data.todos[user.id+"_"+"default_date_key"][1]
		else
			task_date = new Date()
			year = task_date.getFullYear()
			month = task_date.getMonth()
			date = task_date.getDate()
			display_month = ""+(task_date.getMonth()+parseInt(1))
			if display_month.length < 2
				display_month = "0"+display_month
			date_str = @getDate(date,display_month,year)

		if @robot.brain.data.todos[user.id+"_"+"default_time_key"]?
			time_str = @robot.brain.data.todos[user.id+"_"+"default_time_key"][0]
		else
			time_str = "23:59"

		tasks.date_str = date_str
		tasks.task_date = task_date
		tasks.time = time_str
		tasks.child = ""
		tasks.parents = []
		tasks.subtask_list = []

		@robot.brain.data.todos[user.id] ?= []
		@robot.brain.data.todos[user.id].push(tasks)

		
		totalItems = @getItems(user).length

		@robot.brain.data.todos[task_in_context] = []
		@robot.brain.data.todos[task_in_context].push(totalItems)

		message = "New task added in your list.\n\n Task Number: #{totalItems}\n\n Deadline\nDate: #{date_str}\n Time: #{time_str}\n\n Description: #{task_desc}"
		message += "\n\n"
		message += @createListMessage(user)
		msg.send message

	removeItem: (msg) =>
		user 	  = msg.message.user
		user_id   = user.id
		item       = msg.match[1]
		items      = @getItems(user)
		totalItems = items.length
		task_in_context = user_id+"_"+"task_in_context"

		if !item
			if @robot.brain.data.todos[task_in_context]?
				item = @robot.brain.data.todos[task_in_context][0]
				if !item
					message = "No task is present in the context.\nPlease specify the task number to be removed."
					msg.send message
					return
				@robot.brain.data.todos[task_in_context] = []
			else
				message = "No task is present in the context.\nPlease specify the task number to be removed."
				msg.send message
				return
		else
			item = item.trim()

		if totalItems == 0
			message = "There's nothing in your list at the moment."
			msg.send message
			return

		if item isnt 'all' and item > totalItems
			if totalItems > 0
				message = "Task number #{item} doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return

		if item is 'all'
			@clearAllItems(user)
			@robot.brain.data.todos[task_in_context] = []
			message = "All items deleted from list."
		else
			@robot.brain.data.todos[task_in_context][0] = totalItems-1
			task = items[item-1]
			date = task.date_str
			time = task.time
			desc = task.description
			@robot.brain.data.todos[user.id].splice(item - 1, 1)
			message = "Task deleted from list.\n\n Task Number: #{item}\n\nDeadline \nDate: #{date}\nTime: #{time}\n\nDescription: #{desc}"
			message += "\n\n"
			message += @createListMessage(user)

		msg.send message

	updateItem: (msg) =>
		user      = msg.message.user
		item      = msg.match[1]
		desc      = msg.match[2]
		items      = @getItems(user)
		totalItems = items.length
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"
		

		if !item
			if @robot.brain.data.todos[task_in_context]?
				item = @robot.brain.data.todos[task_in_context][0]
				if !item
					message = "No task is present in the context.\nPlease specify the task number to upadte."
					msg.send message
					return
			else
				message = "No task is present in the context.\nPlease specify the task number to update."
				msg.send message
				return


		if item > totalItems
			if totalItems > 0
				message = "That item doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message

			return
		else
			task = items[item-1]
			oldTaskTime = task.time
			oldTaskDesc = task.description
			doesTimeExist = @doesTimeExist(desc)
			if doesTimeExist > 0
				hour = desc.slice(doesTimeExist+1,doesTimeExist+3)
				minutes = desc.slice(doesTimeExist+4,doesTimeExist+6)
				task.time = hour+":"+minutes
				task.description = desc.slice(0,doesTimeExist)
				message = "Details updated.\n\nTask Number: #{item}\n\nPrevious\n Time: #{oldTaskTime}\n Description: #{oldTaskDesc}\n\nCurrent\n Time: #{task.time}\n Description: #{task.description}"
			else
				task.description = desc
				message = "Details updated.\n\nTask Number: #{item}\n\nPrevious\n Description: #{oldTaskDesc}\n\nCurrent\n Description: #{task.description}"
			@robot.brain.data.todos[user.id].splice(item - 1, 1,task)

		message += "\n\n"
		message += @createListMessage(user)
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
				message += "\n------------------------------------------------------------------------------------------------------------\n"
			if today.length > 1
				message += today.join("\n")
				message += 
				"\n------------------------------------------------------------------------------------------------------------\n"
			if tomorrow.length > 1
				message += tomorrow.join("\n")
				message += 
				"\n------------------------------------------------------------------------------------------------------------\n"
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
			empty_status = "P  "
			empty_desc = " "
			empty_note = " "
			if msg["description"]?
				desc_length = msg["description"].length
			if desc_length > 0
				if msg["note"]?
					note_length = 0
				task_string.push(index+".  ")
				task_string.push(msg["date_str"]+" "+msg["time"])
				if msg["status"]?
					task_string.push(msg["status"])
				else
					task_string.push(empty_status)
				task_string.push("                 ")
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
					task_string.push("                                                                             ")
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
