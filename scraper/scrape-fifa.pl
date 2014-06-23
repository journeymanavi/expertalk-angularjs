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
my $DEBUG = 0;

my $start = time();

out("Getting Players data");
my ($playersById, $playersByTeamId) = getPLayers();
print to_json($playersById, {pretty => 1});
print to_json($playersByTeamId, {pretty => 1});

out("Getting Groups data");
my $groups = getGroups();
print to_json($groups, {pretty => 1}) if $DEBUG;

out("Getting Teams data");
my $teams = getTeams(1);
print to_json($teams, {pretty => 1});

out("Getting Matches data");
my $matehs = getMatches();
print to_json($matehs, {pretty => 1});

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

	my $matches = {};
	for my $date (@{$matchesScraper->scrape($matchesURI)->{dates}}) {
		$matches->{$date->{matchDate}} = $date->{matches};
	}
	return $matches;
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

	my $playersById  = {};

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
			jerseyNumber => $rawPlayer->{bibnum}
		};
		$playersById->{$playerId} = $player;
		push @{$playersByTeamId->{$teamId}}, $player;

		if ($DOWNLOAD_PLAYER_IMAGES) {
			my $playerImageURL = "'http://img.fifa.com/images/fwc/2014/players/prt-3/${playerId}.png'";
			out "Downloading Player image for playerId [$playerId] using url [$playerImageURL]";
			if (system("wget -q $playerImageURL -O ./img/player/$playerId.png")) {
				out "[WARNING] - failed to download Player image for playerId [$playerId] : $!";
			}
		}
	}

	return ($playersById, $playersByTeamId);
}

sub populateTeamDetails {
	my $teams = shift;

	my $teamProfileScraper = scraper {
		process '.col-xs-4 tr', 'items[]' => scraper {
			process 'td:nth-of-type(1)', value => 'TEXT';
			process 'td:nth-of-type(2)', item => 'TEXT';
		};
	};

	for my $team (keys(%$teams)) {
		my $teamId = $teams->{$team}->{id};
		my $url = "http://www.fifa.com/worldcup/teams/team=${teamId}/profile.html";
		out "populating profile for team [$team] with id [$teamId] usinf URL [$url]";
		my $teamProfileURI = new URI($url);
		my $profileItems = $teamProfileScraper->scrape($teamProfileURI)->{items};
		for my $profileItem (@$profileItems) {
			$profileItem->{item} =~ s/Last Updated.*$//;
		}
		$teams->{$team}->{profile} = $profileItems;
		$teams->{$team}->{players} = $playersByTeamId->{$teamId};

		my $countryCode = lc($teams->{$team}->{code});

		if ($DOWNLOAD_LOGO_IMAGES) {
			my $logoFileName = "${countryCode}.gif";
			my $teamLogoImageURL = "'http://img.fifa.com/images/logos/m/$logoFileName'";
			out "Downloading Team Logo image for teamId [$teamId] using url [$teamLogoImageURL]";
			if (system("wget -q $teamLogoImageURL -O ./img/team-logo/$logoFileName")) {
				out "[WARNING] - failed to download Team Logo image for teamId [$teamId] : $!";
			}
		}

		if ($DOWNLOAD_FLAG_IMAGES) {
			my $flagFileName = "${countryCode}.png";
			my $size = $countryCode eq 'nga' ? '4' : '5';
			my $flagImageURL = "'http://img.fifa.com/images/flags/$size/$flagFileName'";
			out "Downloading Flag image for teamId [$teamId] using url [$flagImageURL]";
			if (system("wget -q $flagImageURL -O ./img/flag/$flagFileName")) {
				out "[WARNING] - failed to download Flag image for teamId [$teamId] : $!";
			}
		}
	}
}

sub getTeams {
	my $teamsProfile = {
					'Uruguay' => {
											 'group' => 'Group D',
											 'name' => 'Uruguay',
											 'id' => '43930',
											 'code' => 'URU',
											 'profileUrl' => '/worldcup/teams/team=43930/index.html'
										 },
					'Australia' => {
												 'group' => 'Group B',
												 'name' => 'Australia',
												 'id' => '43976',
												 'code' => 'AUS',
												 'profileUrl' => '/worldcup/teams/team=43976/index.html'
											 },
					'Switzerland' => {
													 'group' => 'Group E',
													 'name' => 'Switzerland',
													 'id' => '43971',
													 'code' => 'SUI',
													 'profileUrl' => '/worldcup/teams/team=43971/index.html'
												 },
					'Korea Republic' => {
															'group' => 'Group H',
															'name' => 'Korea Republic',
															'id' => '43822',
															'code' => 'KOR',
															'profileUrl' => '/worldcup/teams/team=43822/index.html'
														},
					'England' => {
											 'group' => 'Group D',
											 'name' => 'England',
											 'id' => '43942',
											 'code' => 'ENG',
											 'profileUrl' => '/worldcup/teams/team=43942/index.html'
										 },
					'Iran' => {
										'group' => 'Group F',
										'name' => 'Iran',
										'id' => '43817',
										'code' => 'IRN',
										'profileUrl' => '/worldcup/teams/team=43817/index.html'
									},
					'Argentina' => {
												 'group' => 'Group F',
												 'name' => 'Argentina',
												 'id' => '43922',
												 'code' => 'ARG',
												 'profileUrl' => '/worldcup/teams/team=43922/index.html'
											 },
					'Russia' => {
											'group' => 'Group H',
											'name' => 'Russia',
											'id' => '43965',
											'code' => 'RUS',
											'profileUrl' => '/worldcup/teams/team=43965/index.html'
										},
					'Honduras' => {
												'group' => 'Group E',
												'name' => 'Honduras',
												'id' => '43909',
												'code' => 'HON',
												'profileUrl' => '/worldcup/teams/team=43909/index.html'
											},
					'Portugal' => {
												'group' => 'Group G',
												'name' => 'Portugal',
												'id' => '43963',
												'code' => 'POR',
												'profileUrl' => '/worldcup/teams/team=43963/index.html'
											},
					'Nigeria' => {
											 'group' => 'Group F',
											 'name' => 'Nigeria',
											 'id' => '43876',
											 'code' => 'NGA',
											 'profileUrl' => '/worldcup/teams/team=43876/index.html'
										 },
					'Cameroon' => {
												'group' => 'Group A',
												'name' => 'Cameroon',
												'id' => '43849',
												'code' => 'CMR',
												'profileUrl' => '/worldcup/teams/team=43849/index.html'
											},
					'Greece' => {
											'group' => 'Group C',
											'name' => 'Greece',
											'id' => '43949',
											'code' => 'GRE',
											'profileUrl' => '/worldcup/teams/team=43949/index.html'
										},
					'Italy' => {
										 'group' => 'Group D',
										 'name' => 'Italy',
										 'id' => '43954',
										 'code' => 'ITA',
										 'profileUrl' => '/worldcup/teams/team=43954/index.html'
									 },
					'Germany' => {
											 'group' => 'Group G',
											 'name' => 'Germany',
											 'id' => '43948',
											 'code' => 'GER',
											 'profileUrl' => '/worldcup/teams/team=43948/index.html'
										 },
					'Ghana' => {
										 'group' => 'Group G',
										 'name' => 'Ghana',
										 'id' => '43860',
										 'code' => 'GHA',
										 'profileUrl' => '/worldcup/teams/team=43860/index.html'
									 },
					'Belgium' => {
											 'group' => 'Group H',
											 'name' => 'Belgium',
											 'id' => '43935',
											 'code' => 'BEL',
											 'profileUrl' => '/worldcup/teams/team=43935/index.html'
										 },
					'Mexico' => {
											'group' => 'Group A',
											'name' => 'Mexico',
											'id' => '43911',
											'code' => 'MEX',
											'profileUrl' => '/worldcup/teams/team=43911/index.html'
										},
					'Chile' => {
										 'group' => 'Group B',
										 'name' => 'Chile',
										 'id' => '43925',
										 'code' => 'CHI',
										 'profileUrl' => '/worldcup/teams/team=43925/index.html'
									 },
					'Colombia' => {
												'group' => 'Group C',
												'name' => 'Colombia',
												'id' => '43926',
												'code' => 'COL',
												'profileUrl' => '/worldcup/teams/team=43926/index.html'
											},
					'USA' => {
									 'group' => 'Group G',
									 'name' => 'USA',
									 'id' => '43921',
									 'code' => 'USA',
									 'profileUrl' => '/worldcup/teams/team=43921/index.html'
								 },
					'Netherlands' => {
													 'group' => 'Group B',
													 'name' => 'Netherlands',
													 'id' => '43960',
													 'code' => 'NED',
													 'profileUrl' => '/worldcup/teams/team=43960/index.html'
												 },
					'Brazil' => {
											'group' => 'Group A',
											'name' => 'Brazil',
											'id' => '43924',
											'code' => 'BRA',
											'profileUrl' => '/worldcup/teams/team=43924/index.html'
										},
					'Japan' => {
										 'group' => 'Group C',
										 'name' => 'Japan',
										 'id' => '43819',
										 'code' => 'JPN',
										 'profileUrl' => '/worldcup/teams/team=43819/index.html'
									 },
					'Costa Rica' => {
													'group' => 'Group D',
													'name' => 'Costa Rica',
													'id' => '43901',
													'code' => 'CRC',
													'profileUrl' => '/worldcup/teams/team=43901/index.html'
												},
					'France' => {
											'group' => 'Group E',
											'name' => 'France',
											'id' => '43946',
											'code' => 'FRA',
											'profileUrl' => '/worldcup/teams/team=43946/index.html'
										},
					'Ecuador' => {
											 'group' => 'Group E',
											 'name' => 'Ecuador',
											 'id' => '43927',
											 'code' => 'ECU',
											 'profileUrl' => '/worldcup/teams/team=43927/index.html'
										 },
					'Bosnia and Herzegovina' => {
																			'group' => 'Group F',
																			'name' => 'Bosnia and Herzegovina',
																			'id' => '44037',
																			'code' => 'BIH',
																			'profileUrl' => '/worldcup/teams/team=44037/index.html'
																		},
					'Croatia' => {
											 'group' => 'Group A',
											 'name' => 'Croatia',
											 'id' => '43938',
											 'code' => 'CRO',
											 'profileUrl' => '/worldcup/teams/team=43938/index.html'
										 },
					'Algeria' => {
											 'group' => 'Group H',
											 'name' => 'Algeria',
											 'id' => '43843',
											 'code' => 'ALG',
											 'profileUrl' => '/worldcup/teams/team=43843/index.html'
										 },
					'Spain' => {
										 'group' => 'Group B',
										 'name' => 'Spain',
										 'id' => '43969',
										 'code' => 'ESP',
										 'profileUrl' => '/worldcup/teams/team=43969/index.html'
									 },
					'Cote d\'Ivoire' => {
														 'group' => 'Group C',
														 'name' => 'Cote d\'Ivoire',
														 'id' => '43854',
														 'code' => 'CIV',
														 'profileUrl' => '/worldcup/teams/team=43854/index.html'
													 }
				};

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
				}
			};
		};

		my $teamsURI = new URI('http://www.fifa.com/worldcup/teams/index.html');

		$teams = {map {$_->{name} => $_} @{$teamsScraper->scrape($teamsURI)->{teams}}};
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