cp = require("child_process")

class Sandbox
  constructor: (@freetimeCB=->)->
    @restart()
  restart: ->
    @child = cp.fork(__dirname + '/shovel.js')
    @cb = @freetimeCB
    @timer = 0
    @child.on "message", (data)=>
      clearTimeout(@timer)
      @cb(data)
      @cb = @freetimeCB
  eval: (code, @cb)->
    @child.send(code)
    @timer = setTimeout (=>
      @cb(["TimeoutError: restarting repl..."])
      @child.kill("SIGKILL")
      @restart()
    ), 10*1000

module.exports = Sandbox