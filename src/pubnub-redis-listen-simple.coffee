#
# PubNub Persistence: node.js replication simple listener
#
# "Connecting your worldwide apps to redis updates within 250ms"
#
# Usage: coffee src/pubnub-redis-listen-simple.coffee CHANNEL_NAME
#      - where CHANNEL_NAME is the Redis channel to receive updates
#

PUBNUB    = require('../deps/pubnub-javascript/node.js/pubnub.js')
_         = require('../deps/underscore/underscore.js')

CHANNEL    = process.argv[2]

pubnub = PUBNUB.init(
  subscribe_key : 'demo' # you should change this!
  publish_key   : 'demo' # you should change this!
)

#
# Set up a simple event listener - we just log the updates
#
pubnub.subscribe({
  channel: CHANNEL
  message: (command) -> console.log "got from \##{CHANNEL}:", JSON.stringify(command)
})

console.log "Listening to PubNub redis channel \##{CHANNEL}"