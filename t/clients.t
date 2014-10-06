use Test::More;
use Test::Mojo;

use FindBin;
require "$FindBin::Bin/../subs.pl";

my $cant = 200;

my $tsender = Test::Mojo->new;
#prepare publisher
$tsender->websocket_ok('/pub')->status_is('101', 'publisher websocket connected');


my $t = Test::Mojo->new;

#
# Single channel example
#

$t->websocket_ok('/sub/channel_alfa')
  ->status_is('101', 'websocket connection')
  ->send_ok("dummy")				# send something to start handshake
  ->message_ok
  ->message_is("echo: dummy");

# publishes message "sample text" to channel "channel_alfa"
$tsender->send_ok("channel_alfa sample text")->message_ok;
# and checks it
$t->message_ok->message_is('M: sample text, C: channel_alfa')->finish_ok;

#
# Now opens $cant different subscription channels
#

my @ta;

for my $i (0..$cant-1) {
	$ta[$i] = Test::Mojo->new;
	$ta[$i]	->websocket_ok("/sub/channel_$i")
			->status_is('101', "websocket connection # $i")
			->send_ok("dummy")				# send something to start handshake
			->message_ok
			->message_is("echo: dummy");
}

#
# ...sends data to the $cant channels
#

for my $i (reverse 0..$cant-1) {
	$tsender->send_ok("channel_$i sample $i")->message_ok;
}

#
# check amount of redis clients at this time
#

my $nclients;
my $maxclients = $cant + 5;
$nclients = $1 if `redis-cli INFO` =~ /connected_clients:(\d+)/;
$nclients //= 0;
ok $nclients > 0 && $nclients < $maxclients, "take less than $maxclients redis clients ($nclients clients)";

#
# ...and checks data on each channel
#

for my $j (0..$cant-1) {
	my $i = ($j*37) % $cant;
	$ta[$i]->message_ok->message_is("M: sample $i, C: channel_$i")->finish_ok;
}

$tsender->finish_ok;

done_testing();