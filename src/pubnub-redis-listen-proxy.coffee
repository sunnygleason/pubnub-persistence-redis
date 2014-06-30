#
# PubNub Persistence: node.js replication proxy listener
#
# "Connecting your worldwide apps to redis updates within 250ms"
#
# Usage: coffee src/pubnub-redis-listen-proxy.coffee CHANNEL_NAME REDIS_ADDR
#      - where CHANNEL_NAME is the Redis channel to receive updates
#      - where REDIS_ADDR is the host:port
#

PUBNUB    = require('../deps/pubnub-javascript/node.js/pubnub.js')
redis     = require('../deps/node_redis/index.js')

CHANNEL    = process.argv[2]
REDIS_ADDR = (process.argv[3] || 'localhost:6379').split(":")
REDIS_HOST = REDIS_ADDR[0]
REDIS_PORT = REDIS_ADDR[1]

client = redis.createClient(REDIS_PORT, REDIS_HOST)

pubnub = PUBNUB.init(
  subscribe_key : 'demo' # you should change this!
  publish_key   : 'demo' # you should change this!
)

#
# Set up a client replicator - we replay updates to the redis client
#
pubnub.subscribe({
  channel:CHANNEL
  message: (command) =>
    commandStr = JSON.stringify(command)
    if command.type == "entity"
      console.log "updating redis with entity:", commandStr
      client.set(command.entity[1], command.entity[2])
    else
      console.log "updating redis with command:", commandStr
      client.send_command(command.command, command.args)
})

console.log "Listening to PubNub redis channel \##{CHANNEL}, replaying to redis instance at #{REDIS_ADDR}"