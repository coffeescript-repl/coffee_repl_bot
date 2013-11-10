util = require("util")
vm   = require("vm")

isEvaluating = false
logs = []
sandbox =
  setTimeout: (cb, delay, args...)->
    if delay < 1000
    then delay = 1000
    else setTimeout.apply(null, [cb, delay].concat(args))
  clearTimeout: clearTimeout
  console:
    log: ->
      str = Array.prototype.map.call(arguments, (v)->
        if typeof v is "string"
        then v
        else util.inspect(v)
      ).join(", ")
      if isEvaluating
      then logs.push(str)
      else process.send([str])
      undefined
sandbox.global = sandbox

process.on "message", (data)->
  isEvaluating = true
  try
    logs.push(
      util.inspect(
        vm.runInNewContext(data, sandbox)))
  catch err
    logs.push(""+err)
  process.send(logs)
  logs = []
  isEvaluating = false
