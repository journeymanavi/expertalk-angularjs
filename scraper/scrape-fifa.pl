#!/usr/bin/perl -w

$|=1;

use strict;
use URI;
use Web::Scraper;
use Data::Dumper;

my $teamsScraper = scraper {
	process 'div.team-map>a.map-item',
		'teams[]' => {
			id => '@id',
			name => '@title',
			'profileUrl' => '@href',
			'groupId' => '@data-idgroup'
		}
};

my $teamsScraperURI = new URI('http://www.fifa.com/worldcup/teams/index.html');

my $result = $teamsScraper->scrape($teamsScraperURI);

print Dumper($result);

my $team = scraper {
	process '', id => 'TEXT';
	process '//*[@id="content-wrap"]/div/div[2]/div/div[1]/h1/text()', name => 'TEXT';
	process '.t-n', '@code' => 'TEXT';
	process '//*[@id="content-wrap"]/div/div[2]/div/div[1]/h1/span/img', flag => '@src';
	process '//*[@id="content-wrap"]/div/div[2]/div/div[1]/div/img', logo => '@src';
};

exit 0;