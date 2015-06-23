# Description:
#   Simple todo app
#
# Dependencies:
#
# Configuration:
#   None
#
# Commands:
#   todo add <description> - Add a new todo with a basic description
#   todo delete <item number | all> - Remove a todo item from the list
#   todo update <item number> - Update the item
#   todo list - List your tasks
#   todo help - Get help with this plugin
#
# Author:
#   vishal singh

class Todos
	constructor: (@robot) ->
		@robot.brain.data.todos = {}

		@robot.respond /todo add (.*)/i, @addItem
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
		description = msg.match[1]

		@robot.brain.data.todos[user.id] ?= []
		@robot.brain.data.todos[user.id].push(description)

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
			@robot.brain.data.todos[user.id].splice(item - 1, 1,desc)

		message = "Item updated."
		msg.send message


	clearAllItems: (user) => @robot.brain.data.todos[user.id].length = 0

	createListMessage: (user) =>
		items = @getItems(user)

		message = ""

		if items.length > 0
			for todo, index in items
				message += "#{index + 1}#    #{todo}\n"
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