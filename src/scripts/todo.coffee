# Description:
#   A todo script.
#
# Commands:
#   todo add  - Add an item into the list
#   todo show - Display the item list.
#   todo help - Display help
#
# Notes:
#   
#
# Author:
#   Vishal Singh
#
module.exports = (robot) ->
  # helper method to get sender of the message
  get_username = (response) ->
    "@#{response.message.user.name}"

  # helper method to get channel of originating message
  get_channel = (response) ->
    if response.message.room == response.message.user.name
      "@#{response.message.room}"
    else
      "##{response.message.room}"

  ###
  #   responds to "[botname] hi"
  ###
  robot.respond /hi/i, (msg) ->
    # responds in the current channel
    msg.send 'Hello! '+get_username(msg)


  ###
  #   Displays the help
  ###
  robot.respond /todo help/i, (msg) ->
   msg.send "\n usage: todo [--help] <command> <args>\n The most commonly used todo commands are:\n\t todo add\t   Add a task to the todo list. e.g. todo add Call Mr. A @ 11:30AM\n\t todo show\tDisplay the item list.\n\t todo help\t  Display the help."

  ###
  #   Add an item into the list"
  ###
  robot.respond /todo add (.*)/i, (msg) ->
    # responds in the current channel
      text = msg.match[1]
      todo_key = robot.brain.get(get_username(msg)+"_key")
      space = "                          "
      count = (robot.brain.get(get_username(msg)+"_key"+"_count") || 1)
      if not todo_key?
       list = "\n"+"Task No_____Task-To-Do_______________________"+"\n"
       robot.brain.set(get_username(msg)+"_key",list+count+space+text)
       robot.brain.set(get_username(msg)+"_key"+"_count",count+1)
       msg.reply " Your task has been added into the list "
      else
       list = robot.brain.get(get_username(msg)+"_key")+ "\n"
       robot.brain.set(get_username(msg)+"_key",list+count+space+text)
       robot.brain.set(get_username(msg)+"_key"+"_count",count+1)
       msg.reply " Your task has been added into the list "

  ###
  #   Show the list
  ###
  robot.respond /todo show/i, (msg) ->
    task_count = (robot.brain.get(get_username(msg)+"_key"+"_count") || 0)
    if  (task_count == 0)
     msg.reply "There's nothing on your list at the moment"
    else
     msg.send robot.brain.get(get_username(msg)+"_key")


  # any message above not yet processed falls here. See the console to examine the object
  # uncomment to test this
  # robot.catchAll (response) ->
  #   console.log('catch all: ', response)
