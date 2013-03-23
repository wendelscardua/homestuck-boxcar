#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;
use CGI;
use POSIX;

my $api = {
	'key'    => 'xxxxxxxxxxxxxxxxxxxx',			# 20 Char Provider API Key
#	'secret' => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',	# 40 Char Provider API Secret
	};

my $key_file = './boxcar-keys.txt';

open my $key_handle, '<', $key_file or die $!;
my $key = <$key_handle>; chomp $key; $api->{key} = $key;
#my $secret = <$key_handle>; chomp $secret; $api->{secret} = $secret;
close $key_handle;

my $subscribe_url = 'http://boxcar.io/devices/providers/' . $api->{key} . '/notifications/subscribe';

my $browser = LWP::UserAgent->new;

my $q = CGI->new;

my $email = $q->param('email') || $ARGV[0];

print $q->header(-type => 'text/html', -charset => 'UTF-8');

print <<"HEAD";
<html>
<head>
<title>Homestuck Update for Boxcar - Subscription</title>
</head>
<body>
<h1>Homestuck Update for Boxcar app - Subscription</h1>

<p>Firstly, if you haven't done so, install the Boxcar app. (<a href="http://boxcar.io">http://boxcar.io</a>, free on iTunes App Store)

<p>Open this app and sign up. While (I hope) they are reviewing my "Homestuck Update" service you won't find it on Boxcar's "Add a service" 
button yet, so that's why I've set up this page - I can subscribe users manually through their API.

<p>Just use the form below to subscribe your email to my service:

HEAD

my $ok = 0;

if ($email) {
	my $response = $browser->post (
			$subscribe_url,
			[
				email => $email			
			]
		);
	if ($response->code == 404) {
		print "<p> The email <", $email, "> is not registered at Boxcar. Open your Boxcar app and sign up first.",$/;
		print "<p> (otherwise, you could have made a typo, check if you wrote your email correctly)",$/;
	} elsif ($response->code == 401) {
		print "<p> How do you expect to subscribe, when your email <",$email,"> is already here ? 8^y" ,$/;
		print "<p> But seriously, we already have your email. You can contact me if you aren't getting any notifications after updates",$/;
		$ok = 1;
	} else {
		print "<p> Thanks for subscribing! You should get a notification next time Homestuck updates.";
		$ok = 1;
	}
}

if (!$ok) {
	print <<"FORM";
	<form action="subscribe.pl" method="get">
	<p> Your email (the one you used for signing up on Boxcar) : 
	<p> <input type="email" name="email">
	<p> <input type="submit">
	</form>
FORM
}

print <<"FOOT";
<hr/>
<p>Posted on Reddit at <a href="http://www.reddit.com/r/homestuck/comments/1as6kk/just_created_a_homestuck_notifier_for_ios_kinda/">http://www.reddit.com/r/homestuck/comments/1as6kk/just_created_a_homestuck_notifier_for_ios_kinda/</a>
<hr/>
<small>
<p>This service is a fan project. This is not official nor affiliated to Homestuck/MSPA/WhatPumpkin
<p>Homestuck is © Andrew Hussie
<p>contact: wendelscardua at gmail.com
</small>
</body>
</html>
FOOT


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
