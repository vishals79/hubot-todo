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
		@robot.respond /assign( [0-9]+){0,1} @([a-zA-Z0-9]+){1}/i, @assignTask
		@robot.respond /notifications/i, @notifications
		@robot.respond /accept( [0-9]+){0,1}/i, @acceptNotification
		@robot.respond /reject( [0-9]+){0,1}/i, @rejectNotification
		@robot.respond /clear/i, @clearNotification

	help: (msg) =>
		message = "\n* add|create <task-description> @hh:mm (optional)
   	    \n\n  task_number = last added task, if <task_number> is not provided
   	    \n\n* update <task_number> <task-description> @hh:mm (optional)
        \n* delete <task_number|all>
        \n* show <task_number>
        \n* note <task_number> <note-description>
        \n* complete <task_number>
        \n* time <task_number> <time in the format hh:mm>
        \n* date <task_number> <date in the format DD-MM-YYYY>
        \n* date <task_number> today+n
        \n* list
        \n* subtask <description> for <parent-task-number>
        \n* default time HH:MM
        \n* default date today+n
        \n* default date <DD-MM-YYYY>
        \n* assign <task_number> @User_Id : Assign task to User_Id
        \n* notifications : Display Notifications
        \n* accept <task_number> : Add task to your list and delete the notification.
        \n* reject <task_number> : Assign task back to the assignor and delete the notification.
        \n* clear: Clear all notifications"
        
        

		msg.send message


	acceptNotification: (msg) =>
		user 	   = msg.message.user
		number = msg.match[1]

		notifications = @getNotification(user)
		totalItems = notifications.length

		if !number
			if totalItems > 0
				number = totalItems
			else
				message = "Notification is not present in the context."
				msg.send message
				return
		if number > totalItems
			if totalItems > 0
				message = "Notification doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message
			return
		else 
			notification = notifications[number-1]
			task = notification.task
			if task?
				ret = @addItemToArray(user.id,task)
				if ret != 0
					@deleteNotification(user,number)
					message = "Task added to your list.\n\n Description: #{task.description}\n Deadline: #{task.date_str} #{task.time}\n\n"
					message += @createNotificationMessage(user)

					msg.send message
				else
					message = "Error occurred while task addition."
					msg.send message
			else
				msg.send "Undefined task."

	rejectNotification: (msg) =>
		user 	   = msg.message.user
		number = msg.match[1]

		notifications = @getNotification(user)
		totalItems = notifications.length

		if !number
			if totalItems > 0
				number = totalItems
			else
				message = "Notification is not present in the context."
				msg.send message
				return
		if number > totalItems
			if totalItems > 0
				message = "Notification doesn't exist."
			else
				message = "There's nothing on your list at the moment"

			msg.send message
			return
		else 
			notification = notifications[number-1]
			task = notification.task
			assignor_id = notification.assignor_id
			assignor_name = notification.assignor_name
			if assignor_id? and assignor_id == user.id
				@deleteNotification(user,number)
				message = "You were the assignor of this task. Notification deleted from the list.\n\n"
				message += @createNotificationMessage(user)
				msg.send message
				return
			if task?
				notification.desc = "Task rejected by #{user.name}"
				ret = @assignNotification(assignor_id,notification)
				if ret != 0
					@deleteNotification(user,number)
					message = "Task assigned back to #{assignor_name}.\n\n Description: #{task.description}\n Deadline: #{task.date_str} #{task.time}\n\n"
					message += @createNotificationMessage(user)

					msg.send message
				else
					message = "Error occurred while performing the operation."
					msg.send message
			else
				msg.send "Undefined task."

	clearNotification: (msg) =>
		user 	= msg.message.user
		user_id_notifications = user.id+"_"+"notifications"
		@robot.brain.data.todos[user_id_notifications] = []

		message = "Notifications cleared"
		msg.send message
		return

	deleteNotification: (user,number) =>
		if user? and number?
			user_id_notifications = user.id+"_"+"notifications"
			notifications = @getNotification(user)
			if number <= notifications.length
				@robot.brain.data.todos[user_id_notifications].splice(number - 1, 1)
				return 1
			else
				return -1
		else
			return -1

	notifications: (msg) =>
		user 	= msg.message.user
		message = @createNotificationMessage(user)

		msg.send message

	assignTask: (msg) =>
		user 	   = msg.message.user
		user_id = user.id
		assignor_name = user.name
		task_number = msg.match[1]
		assignee_name = msg.match[2]
		task_in_context = user_id+"_"+"task_in_context"

		
		assignee_id_rawText = msg.message.rawText
		start_index = assignee_id_rawText.indexOf("@")
		if start_index != -1
			start_index  += 1
			end_index = assignee_id_rawText.indexOf(">")
			if end_index != -1
				assignee_id = assignee_id_rawText.substring(start_index,end_index)
			else
				message = "Error occurred while fetching assignee id."
				msg.send message
				return 
		else
			message = "Error occurred while fetching assignee id."
			msg.send message
			return 

		items      = @getItems(user.id)
		totalItems = items.length

		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context."
					msg.send message
					return
			else
				message = "No task is present in the context."
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
			if assignee_id?
				task = items[task_number-1]
				notification = {}
				notification.task = task
				notification.assignor_name = assignor_name
				notification.assignor_id = user_id
				notification.desc = "Task assigned by #{assignor_name}"
				@assignNotification(assignee_id,notification)
				@robot.brain.data.todos[user.id].splice(task_number - 1, 1)
				@robot.brain.data.todos[task_in_context][0] = totalItems-1

		message = "Task assigned to #{assignee_name}"

		msg.send message

	assignNotification: (user_id,notification) =>
		if user_id? and notification?
			assignee_id_notifications = user_id+"_"+"notifications"
			@robot.brain.data.todos[assignee_id_notifications] ?= []
			@robot.brain.data.todos[assignee_id_notifications].push(notification)
			return 1
		else
			return 0

	showTask: (msg) =>
		user 	   = msg.message.user
		task_number = msg.match[1]
		user_id = user.id
		task_in_context = user_id+"_"+"task_in_context"

		items      = @getItems(user.id)
		totalItems = items.length

		if !task_number
			if @robot.brain.data.todos[task_in_context]?
				task_number = @robot.brain.data.todos[task_in_context][0]
				if !task_number
					message = "No task is present in the context."
					msg.send message
					return
			else
				message = "No task is present in the context."
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
			month_list = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
			date = date.toString()
			month = Number(month)
			if month
				if month >= 0 and month <= month_list.length
					month_str = month_list[month-1]
				else
					return ""

				if date.length < 2
					date = "0"+date
				date_str = date+" "+month_str+" "+year
				return date_str
			else
				""

		return ""

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

		items      = @getItems(user.id)
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

		items      = @getItems(user.id)
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

		items      = @getItems(user.id)
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

		items      = @getItems(user.id)
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

		items      = @getItems(user.id)
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

		items      = @getItems(user.id)
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

		items      = @getItems(user.id)
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

		task = {description:task_desc}

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

		doesTimeExist = @doesTimeExist(task_desc)
		if doesTimeExist > 0
			hour = task_desc.slice(doesTimeExist+1,doesTimeExist+3)
			minutes = task_desc.slice(doesTimeExist+4,doesTimeExist+6)
			isValidTime = @isValidTime(hour,minutes)
			if isValidTime != 1
				msg.send "Opps! It seems time format is not correct.\n Time Format : HH:MM\n00 <= HH <= 23\n00<= MM <=59"
				return

			time_str = hour+":"+minutes
			task_desc = task_desc.slice(0,doesTimeExist)
			task.description = task_desc
		else
			if @robot.brain.data.todos[user.id+"_"+"default_time_key"]?
				time_str = @robot.brain.data.todos[user.id+"_"+"default_time_key"][0]
			else
				time_str = "23:59"

		task.date_str = date_str
		task.task_date = task_date
		task.time = time_str
		task.child = ""
		task.parents = []
		task.subtask_list = []

		ret = @addItemToArray(user.id,task)
		if ret != 0
			message = "New task added in your list.\n\n Task Number: #{ret}\n\n Deadline\nDate: #{date_str}\n Time: #{time_str}\n\n Description: #{task_desc}"
			message += "\n\n"
			message += @createListMessage(user)
		else
			message = "Error occurred while task addition."
		
		msg.send message

	addItemToArray: (user_id,task) =>
		if user_id?
			task_in_context = user_id+"_"+"task_in_context"

			@robot.brain.data.todos[user_id] ?= []
			@robot.brain.data.todos[user_id].push(task)

			
			totalItems = @getItems(user_id).length


			@robot.brain.data.todos[task_in_context] = []
			@robot.brain.data.todos[task_in_context].push(totalItems)

			return totalItems
		else
			return 0

	removeItem: (msg) =>
		user 	  = msg.message.user
		user_id   = user.id
		item       = msg.match[1]
		items      = @getItems(user.id)
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
		items      = @getItems(user.id)
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

	getNotification: (user) => 
		if user?
			user_id = user.id
			user_id_notifications = user_id+"_"+"notifications"
			return @robot.brain.data.todos[user_id_notifications] or []

	createNotificationMessage: (user) =>
		notifications = @getNotification(user)
		message = "                                                                          Notifications              \n\n"
		message += " S.No                             Deadline.                                  Assigned By.                              \n\n"
		values = []
		if notifications? and notifications.length > 0
			for item,index in notifications
				values = []
				task = item["task"]
				if task?
					values.push("\n\n"+(index+1)+".   ")
					values.push(task["date_str"]+" "+task["time"])
					values.push(item["desc"])
					message += "\n"+values.join("                     ")
					message += "\nDescription: "+task["description"]
			return message
		else
			return "You don't have any notification"


	createListMessage: (user) =>
		items = @getItems(user.id)
		notifications = @getNotification(user)
		no_of_notifications = notifications.length

		message = ""
		header = " S.No                                      Deadline.                                          Status                             \n"
		overdue = ["\nOverdue\n"+header]
		today = ["\nToday\n"+header]
		tomorrow = ["\nTomorrow\n"+header]
		someOtherDay = ["\nOther\n"+header]

		current_date = new Date()
		current_date = new Date(current_date.getFullYear(),current_date.getMonth(),current_date.getDate())

		next_date = new Date()
		next_date = new Date(next_date.getFullYear(),next_date.getMonth(),next_date.getDate()+1)

		if items.length > 0
			message += "                                                                           To Do List              \n\n"
			if no_of_notifications > 0
				multiple  = no_of_notifications isnt 1
				message += "   >>> You have #{no_of_notifications} notification"+ (if multiple then 's' else '') + "\n\n"
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
						overdue.push(values.join("                                   "))

					else if date.getMonth() == current_date.getMonth() and date.getDate() == current_date.getDate() and date.getFullYear() == current_date.getFullYear()
						today.push(values.join("                                   "))

					else if date.getMonth() == next_date.getMonth() and date.getDate() == next_date.getDate() and date.getFullYear() == next_date.getFullYear()
						tomorrow.push(values.join("                                   "))

					else
						someOtherDay.push(values.join("                                   "))

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
				task_string.push("   "+index+".  ")
				task_string.push(msg["date_str"]+" "+msg["time"])
				if msg["status"]?
					task_string.push(msg["status"])
				else
					task_string.push(empty_status)
				task_string.push("\nDescription:\n"+msg["description"]+"\n")
			return task_string

	getTaskStringNotInUse: (msg,index) =>
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

	getItems: (user_id) => return @robot.brain.data.todos[user_id] or []

	listItems: (msg) =>
		user   	= msg.message.user
		totalItems = @getItems(user.id).length
		multiple   = totalItems isnt 1

		message = ""

		if totalItems > 0
			message += "#{totalItems} item" + (if multiple then 's' else '') + " in your list\n\n"

		message += @createListMessage(user)

		msg.send message

module.exports = (robot) -> new Todos(robot)
