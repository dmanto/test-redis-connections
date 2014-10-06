#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::Redis2;

my $redis_server = 'localhost:6379';
$redis_server = $ENV{REDISCLOUD_URL} if $ENV{REDISCLOUD_URL};

helper redis => sub { shift->stash->{redis} ||= Mojo::Redis2->new(url => $redis_server)};


websocket '/sub/:channel' => sub {
	my $c = shift;
	my $schann = $c->stash('channel');
	my $tx = $c->tx;
	$c->redis->on(message => sub {
	  my ($self, $message, $channel) = @_;
	  $tx->send("M: $message, C: $channel");
	});

	$c->redis->subscribe("$schann" => sub {
	  my ($self, $err) = @_;
	 
	  $c->app->log->error("Subscription error on channel $schann : $err") if $err;
	});
	$c->on(message => sub {
  		my ($ws, $bytes) = @_;
  		$c->send("echo: $bytes");
		});

};
websocket '/pub' => sub {
	my $c = shift;
	my $tx = $c->tx;
	$c->on(message => sub {
  		my ($ws, $bytes) = @_;
  		if ($bytes =~ /^(\S+)\s(.*)/) {
	  		$c->redis->publish("$1" => "$2");
	  		$c->send("Ok");
  		} else {$c->send("No")}
		});

};

app->start;

