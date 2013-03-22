#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use HTML::Entities;
use Date::Parse;

my $api = {
	'key'    => 'xxxxxxxxxxxxxxxxxxxx',			# 20 Char Provider API Key
	'secret' => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',	# 40 Char Provider API Secret
	};

my $key_file = './boxcar-keys.txt';

open my $key_handle, '<', $key_file or die $!;
my $key = <$key_handle>; chomp $key; $api->{key} = $key;
my $secret = <$key_handle>; chomp $secret; $api->{secret} = $secret;
close $key_handle;

my $broadcast_url = 'http://boxcar.io/devices/providers/' . $api->{key} . '/notifications/broadcast';

my $mspa_url = 'http://www.mspaintadventures.com/rss/rss.xml';

my $icon_url = 'http://scardua.net/mspa-icon.png';

my $save_state_file = './savestate.txt';

my $rss_item_regex = qr%<item>\s*<title>(.*)</title>\s*<description>(.*)</description>\s*<link>(.*)</link>\s*<guid[^>]*>(.*)</guid>\s*<pubDate>(.*)</pubDate>\s*</item>%;

my $browser = LWP::UserAgent->new;

my $previous_date = 0;

if (-e $save_state_file) {
	open my $fh, '<', $save_state_file or die $!;
	$previous_date = 0 + <$fh>;
	close $fh;
}

while(1) {

	my $response = $browser->get($mspa_url);

	my $content = $response->content;

	$content = decode_entities($content);

	my @fresh_items = ();
	
	while($content =~ m/$rss_item_regex/g) {
		my ($title, $description, $link, $guid, $pubDate) = ($1,$2,$3,$4,$5);
#		print "title $title link $link guid $guid pubdate $pubDate\n";
		
		my $item_date = str2time($pubDate);
		
		if ($item_date > $previous_date) {
			my ($number) = ($link =~ m:p=(\d{6}):);
			unshift @fresh_items, { title => $title, number => $number, link => $link, date => $pubDate};
		}
	}

	if (@fresh_items) {
		my $first = $fresh_items[0];
		my $last = $fresh_items[-1];
		#print "Homestuck Update - [", $first->{number}, "~", $last->{number}, "] ", $first->{title}, $/;
		
		$browser->post (
				$broadcast_url,
				[
					'secret' => $api->{secret},
					'notification[message]' => "[" . $first->{number} . "~" . $last->{number} . "] " . $first->{title},
					'notification[from_remote_service_id]' => time,
					'notification[source_url]' => $first->{link},
					'notification[icon_url]' => $icon_url					
				]
			);
		
		
		$previous_date = str2time($last->{date});
		
		open my $fh, '>', $save_state_file or die $!;
		print $fh $previous_date,$/;
		close $fh;
	}

	sleep(60);
}
=pod
my $notification = {
	'from' => 'Boxcar LWP Test',
	'msg'  => 'This is a test: Boxcar User Token via Perl LWP at ' . localtime(time),
	'url'  => 'http://boxcar.io/devices/providers/' . $api->{key} . '/notifications',
	};

my $browser  = LWP::UserAgent->new;
my $response = $browser->post (
	$notification->{url}, [
		'email'                                => $email_md5,
		'secret'                               => $api->{secret},
		'notification[from_screen_name]'       => $notification->{from},
		'notification[message]'                => $notification->{msg},
		'notification[from_remote_service_id]' => time, # Just a unique placeholder
		'notification[redirect_payload]'       => $email_md5,
		'notification[source_url]'             => 'http://your.url.here',
		'notification[icon_url]'               => 'http://your.url.to/image.here',
		],
	);

for my $key (keys %{$response}) { print $key . ': ' . $response->{$key} . "\n"; }

exit;

__END__
=cut
