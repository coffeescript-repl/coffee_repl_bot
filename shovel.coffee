util = require("util")
vm   = require("vm")

({
  isEvaluating: false
  logs: []
  init: ->
    sandbox = @createSandbox()
    process.on "message", (data)=>
      @isEvaluating = true
      try
        @logs.push(util.inspect(vm.runInNewContext(data, sandbox)))
      catch err
        @logs.push(""+err)
      process.send(@logs.join("\n"))
      @logs = []
      @isEvaluating = false
  createSandbox: ->
    tids = []
    env =
      setTimeout: (callback, delay=1000, args...)->
        if delay < 1000
          delay = 1000
        tids.push(setTimeout.apply(null, [callback, delay].concat(args)))
        tids[tids.length-1]
      clearTimeout: clearTimeout
      getTimeouts: -> tids.slice(0)
      console:
        log: =>
          str = Array.prototype.map.call(arguments, (v)->
            if typeof v is "string"
            then v
            else util.inspect(v)
          ).join(", ")
          if @isEvaluating
            @logs.push(str)
          else
            process.send(str)
          undefined
    env.global = env
    env
}).init()

