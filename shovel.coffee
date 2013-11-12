util = require("util")
vm   = require("vm")

isEvaluating = false
logs = []
tids = []
sandbox =
  setTimeout: (cb, delay=1000, args...)->
    if delay < 1000
      delay = 1000
    tids.push setTimeout.apply(null, [cb, delay].concat(args))
    tids[tids.length-1]
  clearTimeout: clearTimeout
  getTimerIDs: -> tids.slice(0)
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
