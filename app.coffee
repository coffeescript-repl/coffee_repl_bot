Twitter = require("twitter")
CoffeeScript = require("coffee-script")
request = require("request")
Sandbox = require("./sandbox")

BOT_ID = "coffee_repl"
reg = new RegExp("@#{BOT_ID}\\s+([\\s\\S]+)")
twit = new Twitter(require("./#{BOT_ID}_key"))
sandbox = new Sandbox (result)=> @tweet(result)

main = ->
  tweet("restarted. "+Date())

  setInterval((->
    if (new Date()).getMinutes() is 0
      tweet("periodical report. "+Date())
  ), 60*1000)

  twit.stream "user", (stream)->
    stream.on "data", ({id_str, user, text})->
      if text? and screen_name isnt BOT_ID and reg.test(text)
        screen_name = user.screen_name
        logging("onTweet", [id_str, screen_name, text])
        compile unescapeCharRef(reg.exec(text)[1]), ({data, error})->
          if error?
          then tweet("@#{screen_name} #{data}", {"in_reply_to_status_id": id_str})
          else
            logging("JavaScript", [data])
            sandbox.eval data, (result)->
              tweet("@#{screen_name} #{result}", {"in_reply_to_status_id": id_str})

logging = (id, ary=[])->
  console.log "######## #{id} ########"
  console.log "## #{Date()}"
  ary.forEach (v)->
    console.log "## #{v}"

tweet = (str, opt={}, i=0)->
  _str = cutStr(140, str)
  logging("sendTweet", [str])
  twit.updateStatus _str, opt, (data)->
    if !data.statusCode?
    then logging("succeeded")
    else
      logging("failed", [data])
      delay = Math.pow(i, 2)*600
      logging("retrying", [delay])
      setTimeout((=> tweet("."+_str, opt, i+1)), delay)
  undefined

cutStr = (n, str)->
  if str.length <= n
  then str
  else str.substr(0, n-3) + "..."

cs2js = (csCode)->
  CoffeeScript.compile(csCode.split("\n").join("\n  "), {bare:true})

unescapeCharRef = (str)->
  [
    ["&quot;", '"']
    ["&amp;",  "&"]
    ["&apos;", "'"]
    ["&lt;",   "<"]
    ["&gt;",   ">"]
  ].reduce(((_str, [before, after])=>
    _str.split(before).join(after)
  ), str)

compile = (code, next)->
  if url = (/^\.import\s+([\S]+)/.exec(code) or ["", false])[1]
    logging("wget", [url])
    request url, (error, response, body)->
      if !error && response.statusCode is 200
      then next({data: body})
      else next({error: true, data: error})
  else
    csCode = "\n"+code+"\n"
    logging("CoffeeScript", [csCode])
    try
      data = cs2js(csCode)
      setImmediate -> next({data: data})
    catch err
      setImmediate -> next({error: true, data: ""+err})
  undefined

main()