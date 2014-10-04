test-redis-connections
======================

Mojolicious app to check amount of redis connections

The application is based on Mojolicious::Lite and uses Mojo::Redis2 to connect to a local
Redis database.

Redis database must be active on localhost, or a remote connection to a database according
to REDISCLOUD_URL environment variable.

to run the test, enter

./subs.pl test

The test keeps 50 websockets open, each one subscribed to a different redis channel, waiting
for messages that will transmit to the connected websocket client.

After all websockets are open, it measures the amount of clients connected to redis DB. The problem
is that this number is 53 in my system, but according to Mojo::Redis2 documentation this client connections
are reused, so the number should be much less than that.


