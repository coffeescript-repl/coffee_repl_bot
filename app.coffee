Twitter = require("twitter")
CoffeeScript = require("coffee-script")
LiveScript = require("LiveScript")
Sandbox = require("./sandbox")

class ReplBot
  constructor: (@BOT_ID)->
    @REG = RegExp("@#{@BOT_ID}\\s+([\\s\\S]+)")
    @compiler = CoffeeScript
    @twit = new Twitter(require("./#{@BOT_ID}_key"))
    @sandbox = new Sandbox (results)=>
      console.log "######## setTimeout ######## " + Date()
      @tweet(results.join("\n"))
    @tweet("restarted.", {})
    @twit.stream "user", (stream)=>
      stream.on "data", (data)=>
        if data.text? and
           data.user.screen_name isnt @BOT_ID and
           @REG.test(data.text)
          @reply(data)
  reply: (data)->
    console.log "######## OnReply ######## " + Date()
    console.log "# " + data.id_str
    console.log "# " + data.user.screen_name
    console.log "# " + data.text
    console.log "## CoffeeScript"
    console.log csCode =
      "\n" + unescapeCharRef(
        @REG.exec(data.text)[1])+"\n"
    if /[\"\']use coffeescript[\"\']/i.test csCode
      @compiler = CoffeeScript
    else if /[\"\']use livescript[\"\']/i.test csCode
      @compiler = LiveScript
    console.log "## JavaScript"
    try
      console.log jsCode =
        @compiler.compile(
          csCode.split("\n").join("\n  "),
          {bare:true})
    catch err
      console.log err
      return @tweet("@#{data.user.screen_name} "+err, {"in_reply_to_status_id": data.id_str})
    console.log "## Sandbox"
    @sandbox.eval jsCode, (results)=>
      console.log results
      @tweet("@#{data.user.screen_name} #{results.join("\n")}",
             {"in_reply_to_status_id": data.id_str})
  tweet: (str, opt, i=0)->
    _str = if str.length <= 140 then str
    else                             str.substr(0, 137) + "..."
    console.log "######## SendMessage ######## " + Date()
    console.log "# " + i
    console.log "# " + _str
    @twit.updateStatus _str, opt, (data)=>
      if !data.statusCode?
        console.log "## Success"
      else
        console.log data
        setTimeout (=>
          @tweet("."+_str, opt, i+1)), i*2500
  unescapeCharRef = (str)->
    dic =
      "&quot;": '"'
      "&amp;": "&"
      "&apos;": "'"
      "&lt;": "<"
      "&gt;": ">"
    for k,v of dic
      str = str.split(k).join(v)
    str


new ReplBot("coffee_repl")