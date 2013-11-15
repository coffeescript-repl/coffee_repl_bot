child_process = require("child_process")

class Sandbox
  constructor: (@handler)->
    @child = child_process.fork(__dirname + '/shovel.js')
    @timer = 0
    @callback = @handler
    @child.on "message", (result)=>
      clearTimeout(@timer)
      @callback(result)
      @callback = @handler
  eval: (code, @callback)->
    @child.send(code)
    @timer = setTimeout((=>
      @child.kill("SIGKILL")
      @callback("TimeoutError: restarting repl...")
      @constructor.apply(@)
    ), 10*1000)

module.exports = Sandbox