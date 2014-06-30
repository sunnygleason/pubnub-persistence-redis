#
# PubNub Persistence: node.js replication handler
#
# "Connecting your worldwide apps to redis updates within 250ms"
#
# Usage: coffee src/pubnub-redis-replicate.coffee REDIS_ADDR CHANNEL_NAME
#      - where REDIS_ADDR is the host:port
#      - where CHANNEL_NAME is the Redis channel to receive updates
#

PUBNUB    = require('../deps/pubnub-javascript/node.js/pubnub.js')
redisSync = require('../deps/redis-sync/redis-sync.js')
_         = require('../deps/underscore/underscore.js')

pubnub = PUBNUB.init(
  subscribe_key : 'demo' # you should change this!
  publish_key   : 'demo' # you should change this!
)

REDIS_ADDR = (process.argv[2] || 'localhost:6379').split(":")
REDIS_HOST = REDIS_ADDR[0]
REDIS_PORT = REDIS_ADDR[1]
CHANNEL    = process.argv[3]

# NOTE: this is just a partial list!
COMMANDS_TO_REPLICATE = ['set','mset','del','persist','rename','incr','incrby','decr','decrby','expire','expireat','pexpire','pexpireat','append']
COMMANDS_TO_REPLICATE_MAP = _(COMMANDS_TO_REPLICATE).reduce (a, x) -> 
  a[x] = true
  a
, {}

# utility function for stringifying arguments
asString = (e) -> _.map(e, (x) -> x.toString())

#
# Create a Redis Sync instance (replication slave client)
#
sync = new redisSync.Sync()

#
# Set up RDB (Redis database) transfer events
#
sync.on 'rdb', (rdb) ->
  console.log('starting RDB transfer')
  rdb.on 'error',  (err) -> console.error('ERROR!', err)
  rdb.on 'end', () -> console.log('end of RDB')

#
# Set up RDB entity event handler
#
sync.on 'entity', (e) ->
  entity = asString(e)
  console.log 'Publishing entity:', JSON.stringify(entity)
  pubnub.publish {channel:CHANNEL,message:{type:'entity',uuid:pubnub.uuid(),entity:entity}}

#
# Set up Redis command handler
#
sync.on 'command', (command, args) ->
  entity = asString(args)
  if COMMANDS_TO_REPLICATE_MAP[command]
    payload = {channel:CHANNEL,message:{type:'command',uuid:pubnub.uuid(),command:command,args:entity}}
    console.log 'Publishing command:', JSON.stringify(payload)
    pubnub.publish payload
  else
    console.log 'Not publishing command:', JSON.stringify({command:command,args:entity})

# inline command (typically PING)
sync.on 'inlineCommand', (buffers) -> console.log('inline command (not published)', buffers.toString())

# error handler for general error events
sync.on 'error', (err) -> console.error('ERROR!', err)

# Start up and go!
console.log "Replicating from Redis host #{REDIS_ADDR} to PubNub channel \##{CHANNEL}"
sync.connect(REDIS_PORT, REDIS_HOST)
