# Description:
#   Simple todo app
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#   todo add <task name> -d <description> -t|-c|-p|-s <optional flags> <flag values>- Add a new todo with -d - description  -t time (DD-MM-YYYY) -c category(Three characters category. Default "Oth") -p priority(H-High,M-Medium or L-Low) -s status (C\c-Complete I\i - Incomplete P\p - Pending)
#   todo delete <item number | all> - Remove a todo item from the list.
#   todo update <item number> - Update the item
#   todo show - List your tasks
#   todo help - Get help with this plugin
#
# Author:
#   vishal singh

class Todos
	constructor: (@robot) ->
		@robot.brain.data.todos = {}

		@robot.respond /todo add (.*) -d (.*)/i, @addItem
		@robot.respond /todo delete ([0-9]+|all)/i, @removeItem
		@robot.respond /todo show/i, @listItems
		@robot.respond /todo help/i, @help
		@robot.respond /todo update ([0-9]+) (.*)/i, @updateItem

	help: (msg) =>
		commands = @robot.helpCommands()
		commands = (command for command in commands when command.match(/todo/))

		msg.send commands.join("\n")

	addItem: (msg) =>
		user 	   = msg.message.user
		task_name = msg.match[1]
		task_desc = msg.match[2]

		isTimeExist = @doesTimeExist(task_desc)
		isCategoryExist = @doesCategoryExist(task_desc)
		isPriorityExist = @doesPriorityExist(task_desc)
		isStatusExist = @doesStatusExist(task_desc)

		descEndIndex = @endOfDesc([isTimeExist,isCategoryExist,isPriorityExist,isStatusExist])
		if descEndIndex != -1
			description = task_desc.slice(0,descEndIndex)
		else
			description = task_desc

		tasks = {name:task_name, description:description}

		if isTimeExist != -1
			date = task_desc.slice(isTimeExist+3,isTimeExist+6)
			month = task_desc.slice(isTimeExist+7,isTimeExist+9)
			year = task_desc.slice(isTimeExist+10,isTimeExist+14)
			task_time = new Date(year,month,date)
			task_time_str = task_time.toDateString()
			isValidDate = @isValidDate(task_desc,isTimeExist)
			if isValidDate != 1
				msg.send "Opps! It seems time format is not correct.\n Time Format : DD-MM-YYYY\n01 <= DD <= 31\n01<=MM<=11\n2015<=YYYY<=2099"
				return

		else
			task_time = new Date()
			task_time = new Date(task_time.getFullYear(),task_time.getMonth(),task_time.getDate())
			task_time_str = task_time.toDateString()
		
		tasks.time = task_time_str
		tasks.task_time = task_time

		if isCategoryExist != -1
			category = task_desc.slice(isCategoryExist+3,isCategoryExist+7)
		else
			category = "Oth"

		tasks.category = category

		if isPriorityExist != -1
			priority = task_desc.slice(isPriorityExist+3,isPriorityExist+5)
		else
			priority = "L"

		tasks.priority = priority

		if isStatusExist != -1
			status = task_desc.slice(isStatusExist+3,isStatusExist+5)
		else
			status = "I"

		tasks.status = status

		@robot.brain.data.todos[user.id] ?= []
		@robot.brain.data.todos[user.id].push(tasks)

		totalItems = @getItems(user).length
		multiple   = totalItems isnt 1

		message = "#{totalItems} item" + (if multiple then 's' else '') + " in your list\n\n"

		msg.send message

	isValidDate: (text, index) =>
	 date_str = text.slice(index+3,index+14)
		if date_str?
		 doesMatch = date_str.match /(0[1-9]|[1-2][0-9]|3[0-1])-(0[1-9]|1[0-1])-(201[5-9]|20[2-9][0-9])/
		 if doesMatch?
		   return 1
		 else
		   return -1

	endOfDesc: (indexes) =>
		endIndex = -1
		for index in indexes
		 if index != -1 and endIndex < 0
				endIndex = index
		 if index != -1 and endIndex > 0 and index < endIndex
				endIndex = index
	 return endIndex

	doesTimeExist: (desc) =>
		output = desc.indexOf(" -t ")
		if output != -1
			return output
		else
			return -1

	doesPriorityExist: (desc) =>
		output = desc.indexOf(" -p ")
		if output != -1
			return output
		else
			return -1

	doesCategoryExist: (desc) =>
		output = desc.indexOf(" -c ")
		if output != -1
			return output
		else
			return -1
			
	doesStatusExist: (desc) =>
		output = desc.indexOf(" -s ")
		if output != -1
			return output
		else
			return -1

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
			@robot.brain.data.todos[user.id].splice(item - 1, 1,desc)

		message = "Item updated."
		msg.send message


	clearAllItems: (user) => @robot.brain.data.todos[user.id].length = 0

	createListMessage: (user) =>
		items = @getItems(user)

		message = ""
		overdue = ["\n   Overdue\n"]
		today = ["\n   Today\n"]
		tomorrow = ["\n   Tomorrow\n"]
		someOtherDay = ["\n   Some Other Day\n"]

		current_date = new Date()
		current_date = new Date(current_date.getFullYear(),current_date.getMonth(),current_date.getDate())

		next_date = new Date()
		next_date = new Date(next_date.getFullYear(),next_date.getMonth(),next_date.getDate()+1)

		if items.length > 0
			message += "                                                                           To Do List              "
			for todo, index in items
				values = []
				values.push(index + 1)
				values.push(todo["name"])
				values.push(todo["description"])
				values.push(todo["time"])
				values.push(todo["category"])
				values.push(todo["priority"])
				values.push(todo["status"])

				date = new Date(todo["task_time"])
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
				message += "\n----------------------------------------------------------------------------------------------------------------------\n"
			if today.length > 1
				message += today.join("\n")
				message += "\n-------------------------------------------------------------------------------\n"
			if tomorrow.length > 1
				message += tomorrow.join("\n")
				message += "\n-------------------------------------------------------------------------------\n"
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