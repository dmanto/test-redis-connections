use Test::More;
use Test::Mojo;
use Mojo::Redis2;

use FindBin;
require "$FindBin::Bin/../subs.pl";

my $t = Test::Mojo->new;

my $redis_server = 'localhost:6379';
$redis_server = $ENV{REDISCLOUD_URL} if $ENV{REDISCLOUD_URL};
my $redis = Mojo::Redis2->new(url => $redis_server);

#
# Single channel example
#

$t->websocket_ok('/sub/channel_alfa')
  ->status_is('101', 'websocket connection')
  ->send_ok("dummy")				# send something to start handshake
  ->message_ok
  ->message_is("echo: dummy");

$redis->publish(channel_alfa => 'sample text');

$t->message_ok->message_is('M: sample text, C: channel_alfa')->finish_ok;

#
# Now opens 50 different subscription channels
#

my @ta;

for my $i (0..49) {
	$ta[$i] = Test::Mojo->new;
	$ta[$i]	->websocket_ok("/sub/channel_$i")
			->status_is('101', "websocket connection # $i")
			->send_ok("dummy")				# send something to start handshake
			->message_ok
			->message_is("echo: dummy");
}

#
# ...sends data to the 50 channels
#

for my $i (reverse 0..49) {
	$redis->publish("channel_$i" => "sample $i");
}

#
# check amount of redis clients at this time
#

my $nclients;
$nclients = $1 if `redis-cli INFO` =~ /connected_clients:(\d+)/;
$nclients //= 0;
ok $nclients > 0 && $nclients < 5, "take less than 5 redis clients ($nclients clients)";

#
# ...and checks data on each channel
#

for my $j (0..49) {
	my $i = ($j*37) % 50;
	$ta[$i]->message_ok->message_is("M: sample $i, C: channel_$i")->finish_ok;
}


done_testing();