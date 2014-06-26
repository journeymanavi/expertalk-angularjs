#!/usr/bin/perl -w

$|=1;

use strict;
use URI;
use Web::Scraper;
use Data::Dumper;
use JSON;

my $DOWNLOAD_PLAYER_IMAGES = 0;
my $DOWNLOAD_FLAG_IMAGES = 0;
my $DOWNLOAD_LOGO_IMAGES = 0;
my $IMG_DIR = "../fifaworldcup/src/main/webapp/WEB-INF/img";
my $DATA_DIR = "../fifaworldcup/src/main/resources";
my $DEBUG = 0;

my $start = time();

out("Getting Players data");
my ($players, $playersByTeamId) = getPLayers();
open PLAYER_FILE, ">", "${DATA_DIR}/players.json" or die "Failed to open player data file for writing: $!";
print PLAYER_FILE to_json($players, {pretty => 1});
close PLAYER_FILE;
#print to_json($playersByTeamId, {pretty => 1});

out("Getting Groups data");
my $groups = getGroups();
#print to_json($groups, {pretty => 1}) if $DEBUG;

out("Getting Teams data");
my $teams = getTeams(1);
open TEAM_FILE, ">", "${DATA_DIR}/teams.json" or die "Failed to open teams data file for writing: $!";
print TEAM_FILE to_json($teams, {pretty => 1});
close TEAM_FILE;

out("Getting Matches data");
my $matches = getMatches();
open MATCHES_FILE, ">", "${DATA_DIR}/matches.json" or die "Failed to open matches data file for writing: $!";
print MATCHES_FILE to_json($matches, {pretty => 1});
close MATCHES_FILE;

out("Done");

exit 0;

sub getMatches {
	my $datesSelector = join(",", (map {"div[id^=\"201406$_\"]"} (1,20..26)));
	my $matchesScraper = scraper {
		process $datesSelector, 'dates[]' => scraper {
			process 'div', matchDate => '@id';
			process 'div.result,div.fixture,div.live', 'matches[]' => scraper {
				process '.mu-i-date', date => 'TEXT';
				process '.mu-i-datetime', time => sub {
					my $time = ($_->content_list())[0];
					$time =~ /(\d{2}:\d{2})/ ? return $1 : return undef;
				};
				
				process '.mu-i-group', group => 'TEXT';
				process '.mu-i-stadium', stadium => 'TEXT';
				process '.mu-i-venue', venue => 'TEXT';
				
				process '.mu-m .home', homeTeamId => '@data-team-id';
				process '.mu-m .home .t-nText', homeTeamName => sub {scrubTeamName($_->as_trimmed_text())};
				process '.mu-m .home .t-nTri', homeTeamCode => 'TEXT';
				
				process '.mu-m .away', awayTeamId => '@data-team-id';
				process '.mu-m .away .t-nText', awayTeamName => sub {scrubTeamName($_->as_trimmed_text())};
				process '.mu-m .away .t-nTri', awayTeamCode => 'TEXT';
				
				process 'div', status => sub {
					my $class = $_->attr('class');
					$class =~ /fixture/ ? 'Scheduled' : ($class =~ /live/ ? 'Live' : ($class =~ /result/ ? 'Full-time' : ''));
				};

				process '.s-scoreText', score => sub {
					my $scoreText = $_->as_text();
					$scoreText =~ /(\d+)-(\d+)/ ? return {home => $1, away => $2} : undef;
				};
			};
		};
	};

	my $matchesURI = new URI('http://www.fifa.com/worldcup/matches/index.html');

	# read from file
	# my $matchesURI;
	# open IN, "<", "./matches-page.html" or die $!;
	# { local $/ = undef; $matchesURI = <IN>; }

	# Map of matches by date
	# my $matches = {};
	# for my $date (@{$matchesScraper->scrape($matchesURI)->{dates}}) {
	# 	$matches->{$date->{matchDate}} = $date->{matches};
	# }
	# return $matches;

	#List of matches
	return $matchesScraper->scrape($matchesURI)->{dates};
}

sub out {
	print STDERR seconds()." ".shift."\n";
}

sub seconds {
	return time() - $start;
}

sub scrubTeamName {
	my $teamName = shift;
	$teamName =~ s/\x{f4}/o/ if defined($teamName);
	return $teamName;
}

sub getPLayers {
	my $fieldPosition = {
		1 => 'Goalkeeper',
		2 => 'Defender',
		3 => 'Midfielder',
		4 => 'Forward'
	};

	my $players  = [];

	my $playersByTeamId = {};

	my $playersJSONScraper = scraper {
		process 'script#playerJSon', playersJSON => sub { ($_->content_list())[0]; };
	};

	my $playersJSONURI = new URI("http://www.fifa.com/worldcup/players/browser/index.html");

	my $playersJSON = from_json($playersJSONScraper->scrape($playersJSONURI)->{playersJSON});

	for my $rawPlayer (@$playersJSON) {
		my $playerId = $rawPlayer->{idplayer};
		my $teamId = $rawPlayer->{idteam};
		my $player = {
			id => $playerId,
			name => $rawPlayer->{webname},
			teamName => scrubTeamName($rawPlayer->{teamname}),
			teamId => $teamId,
			teamCode => $rawPlayer->{countrycode},
			club => $rawPlayer->{clubname},
			fieldPosition => $fieldPosition->{$rawPlayer->{fieldpos}},
			dob => $rawPlayer->{birthdate},
			jerseyNumber => $rawPlayer->{bibnum},
			featured => isFeaturedPlayer($playerId)
		};
		push @{$players}, $player;
		push @{$playersByTeamId->{$teamId}}, $player;

		if ($DOWNLOAD_PLAYER_IMAGES) {
			my $playerImageURL = "'http://img.fifa.com/images/fwc/2014/players/prt-3/${playerId}.png'";
			out "Downloading Player image for playerId [$playerId] using url [$playerImageURL]";
			if (system("wget -q $playerImageURL -O ${IMG_DIR}/player/$playerId.png")) {
				out "[WARNING] - failed to download Player image for playerId [$playerId] : $!";
			}
		}
	}

	return ($players, $playersByTeamId);
}

sub isFeaturedPlayer {
	my $id = shift;
	return 229397 == $id ? "true" : "false";
}

sub populateTeamDetails {
	my $teams = shift;

	my $teamProfileScraper = scraper {
		process '.col-xs-4 tr', 'items[]' => scraper {
			process 'td:nth-of-type(1)', value => 'TEXT';
			process 'td:nth-of-type(2)', item => 'TEXT';
		};
	};

	for my $team (@$teams) {
		my $teamId = $team->{id};
		my $url = "http://www.fifa.com/worldcup/teams/team=${teamId}/profile.html";
		out "populating profile for team [$team->{name}] with id [$teamId] usinf URL [$url]";
		my $teamProfileURI = new URI($url);
		my $profileItems = $teamProfileScraper->scrape($teamProfileURI)->{items};
		for my $profileItem (@$profileItems) {
			$profileItem->{item} =~ s/Last Updated.*$//;
		}
		$team->{profile} = $profileItems;
		$team->{players} = $playersByTeamId->{$teamId};

		my $countryCode = lc($team->{code});

		if ($DOWNLOAD_LOGO_IMAGES) {
			my $logoFileName = "${countryCode}.gif";
			my $teamLogoImageURL = "'http://img.fifa.com/images/logos/m/$logoFileName'";
			out "Downloading Team Logo image for teamId [$teamId] using url [$teamLogoImageURL]";
			if (system("wget -q $teamLogoImageURL -O ${IMG_DIR}/team-logo/$logoFileName")) {
				out "[WARNING] - failed to download Team Logo image for teamId [$teamId] : $!";
			}
		}

		if ($DOWNLOAD_FLAG_IMAGES) {
			my $flagFileName = "${countryCode}.png";
			my $size = $countryCode eq 'nga' ? '4' : '5';
			my $flagImageURL = "'http://img.fifa.com/images/flags/$size/$flagFileName'";
			out "Downloading Flag image for teamId [$teamId] using url [$flagImageURL]";
			if (system("wget -q $flagImageURL -O ${IMG_DIR}/flag/$flagFileName")) {
				out "[WARNING] - failed to download Flag image for teamId [$teamId] : $!";
			}
		}
	}
}

sub getTeams {
	my $teamLogoUrl = "http://img.fifa.com/images/logos/m/alg.gif";

	if (shift) {
		my $teamsScraper = scraper {
			process 'div.team-map>a.map-item', 'teams[]' => {
				id => sub {
					$1 if $_->attr('href') =~ /team=(\d+)/;
				},
				code => '@id',
				name => sub {scrubTeamName($_->attr('title'))},
				'group' => sub {
					$groups->{$_->attr('data-idgroup')}
				},
				featured => sub {$_->attr('id') eq 'BRA' ? 'true' : 'false';}
			};
		};

		my $teamsURI = new URI('http://www.fifa.com/worldcup/teams/index.html');

		# Teams as Map
		#$teams = {map {$_->{name} => $_} @{$teamsScraper->scrape($teamsURI)->{teams}}};

		# Teams as list
		$teams = $teamsScraper->scrape($teamsURI)->{teams};
	}

	populateTeamDetails($teams);

	return $teams;
}

sub getGroups {
	my $groups = {
		'255947' => 'Group H',
		'255943' => 'Group F',
		'255939' => 'Group D',
		'255935' => 'Group B',
		'255941' => 'Group E',
		'255933' => 'Group A',
		'255945' => 'Group G',
		'255937' => 'Group C'
	};

	if (shift) {
		my $groupsScraper = scraper {
			process '.nav-pills.lev1.nav.anchor li a', 'groups[]' => sub {
				my $id = $_->attr('data-ref');
				$id =~ s/#//;
				my $name = ($_->content_list())[0]->as_text;
				return { id => $id, name => $name } if $name =~ /Group [A-Z]/;
			};
		};

		my $groupsURI = new URI('http://www.fifa.com/worldcup/groups/index.html');

		$groups = {
			map 
			{ref($_) eq 'HASH' ? ($_->{id} => $_->{name}) : (undef=>undef)} 
			@{$groupsScraper->scrape($groupsURI)->{groups}}
		};
	}

	return $groups;
}