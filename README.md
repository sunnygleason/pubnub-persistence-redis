# PubNub Persistence - Redis Replication Edition

Welcome to a growing collection of persistence adapters for
PubNub using Node.JS. In this sample, we present a proof-of-concept
for globally replicating Redis data using PubNub.

NOTE: this is not production-ready! It is supposed to provoke
inspiration and conversation while we work, test and get the
bugs out. Thanks so much for checking it out!

# Before you begin

* IMPORTANT! Make sure that you register for a new PubNub account, and use your own subscription key for any of these samples.
* Note that RDB-based replication only works with RDB file format 2.4 (hopefully 2.6+ coming soon! in the meantime, updates work)
* Note that all dependencies should be included in the "deps" folder - let us know if we missed one!
* If you need to know the revision or source of a dependency, check the GIT_REV or .git_config files in that directory respectively
* Note that this proof-of-concept currently only supports a small subset of Redis write commands
* Note that this has not been scale tested! It is merely nifty and awesome...

# Understanding the 2 Phases of Redis Slave Replication

Redis replication consists of 2 phases:

* Phase 1: the slave connects to the master and gets a dump of all entities as an RDB file
* Phase 2: the slave starts receiving updates in real-time

The current Redis replicator can read RDB files from Redis
2.4 and earlier. We're investigating adding support for 2.6+
soon! Even if Phase 1 isn't working for you, it is very likely
that Phase 2 will work for receiving real-time updates.

# Running the code: Starting a Redis Replicator

To start a Redis replication client, use this command:

```
$ node lib/pubnub-redis-replicate.js localhost:6379 redisrepl
```

This starts up the replication process. You should see something like this:

```
Replicating from Redis host localhost,6379 to PubNub channel #redisrepl
starting RDB transfer
Publishing entity: ["0","food22","0101"]
Publishing entity: ["0","foo","bar"]
Publishing entity: ["0","food","bard"]
Publishing entity: ["0","fooooo","1234523421"]
Publishing entity: ["0","food1","bard1"]
Publishing entity: ["0","food2","2"]
end of RDB
inline command (not published) PING
inline command (not published) PING
```

What happened? The replication client connected to your redis instance,
started an RDB replication transfer, and sent all of the entities to the
PubNub channel "redisrepl".

The PING commands are harmless - they are just there because the replication
client needs to stay connected to the server.

That wasn't bad, was it? Let's try an update!

```
$ redis-cli SET awesome true
OK
```

You should see something like this:

```
Publishing command: {"channel":"redisrepl","message":{"type":"command","uuid":"a70acea6-196b-4cfb-a387-7a50ff24227e","command":"set","args":["awesome","true"]}}
```

Pretty awesome! That means that the replication client saw the update,
and sent it out on the "redisrepl" channel.


# Running the code: Starting a replication listener

To start a Redis replication listener, use this command:

```
$ node lib/pubnub-redis-listen-simple.js redisrepl
```

This starts a listener on the given pubnub channel. You can
modify the listener to do whatever you want with the data
it receives! (This one just logs to console)

As you perform updates, you should see messages like this:

```
got from #redisrepl: {"type":"command","uuid":"1ba99878-b391-404d-afc2-8e2124bb2bf5","command":"set","args":["awesome","true"]}
```


# Running the code: Starting a replication proxy

```
$ node lib/pubnub-redis-listen-proxy.js redisrepl localhost:6399
```

This starts a listener on the given pubnub channel that proxies data
to another redis instance on port 6399.

As you perform updates, you should see messages like this:

```
updating redis with command: {"type":"command","uuid":"85b436fb-1abd-4061-aeee-c73b57c452f0","command":"set","args":["awesome","true"]}
```

If you check the redis instance on port 6399, you should see something like this:

```
$ ./src/redis-cli -p 6399 GET awesome
"true"
```

# Summing it all up

We hope you enjoyed this example of replicating Redis data using PubNub and Node.JS.
In the future, we'll implement and review more Redis commands, and start getting this
sample code a bit more production-ready. If you run into any issues or have any
suggestions for making this more awesome, please drop us a line!



