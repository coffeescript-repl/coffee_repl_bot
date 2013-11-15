Twitter = require("twitter")
CoffeeScript = require("coffee-script")
request = require("request")
Sandbox = require("./sandbox")

({
  BOT_ID: "coffee_repl"
  init: ->
    @reg = RegExp("@#{@BOT_ID}\\s+([\\s\\S]+)")
    @twit = new Twitter(require("./#{@BOT_ID}_key"))
    @sandbox = new Sandbox (result)=> @tweet(result)
    @tweet("restarted. "+Date())
    @twit.stream "user", (stream)=>
      stream.on "data", ({id_str, user, text})=>
        if text? and screen_name isnt @BOT_ID and @reg.test(text)
          screen_name = user.screen_name
          console.log "######## onTweet ########"
          console.log "## "+Date()
          console.log "## "+id_str
          console.log "## "+screen_name
          console.log "## "+text
          @compile @unescapeCharRef(@reg.exec(text)[1]), ({data, error})=>
            if error?
              @tweet("@#{screen_name} #{data}", {"in_reply_to_status_id": id_str})
            else
              console.log "## JavaScript"
              console.log data
              @sandbox.eval data, (result)=>
                @tweet("@#{screen_name} #{result}", {"in_reply_to_status_id": id_str})
  compile: (code, next)->
    if url = (/^\.import\s+([\S]+)/.exec(code) or ["", false])[1]
      console.log "## wget "+url
      request url, (error, response, body)->
        if !error && response.statusCode is 200
          next({data: body})
        else
          next({error: true, data: error})
    else
      console.log "## !wget "+url
      console.log "## CoffeeScript"
      console.log csCode = "\n"+code+"\n"
      try
        setImmediate => next({data: @cs2js(csCode)})
      catch err
        setImmediate -> next({error: true, data: ""+err})
      undefined
  tweet: (str, opt={}, i=0)->
    _str = @cutStr(140, str)
    console.log "######## sendTweet ########"
    console.log "## "+Date()
    console.log "## "+str
    @twit.updateStatus _str, opt, (data)=>
      if !data.statusCode?
        console.log "## succeeded."
      else
        console.log "## failed."
        console.log data
        console.log "## retrying..."+Math.pow(i, 2)*600
        setTimeout((=> @tweet("."+_str, opt, i+1)), Math.pow(i, 2)*600)
    undefined
  cutStr: (n, str)->
    if str.length <= n then str
    else                    str.substr(0, n-3) + "..."
  cs2js: (csCode)->
    CoffeeScript.compile(csCode.split("\n").join("\n  "), {bare:true})
  unescapeCharRef: (str)->
    [
      ["&quot;", '"']
      ["&amp;",  "&"]
      ["&apos;", "'"]
      ["&lt;",   "<"]
      ["&gt;",   ">"]
    ].reduce(((_str, [before, after])=>
      _str.split(before).join(after)
    ), str)
}).init()

