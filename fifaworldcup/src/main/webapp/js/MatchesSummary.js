function MatchesSummary(obj) {
	this.allMatches = obj;

	this.getLatestResults = function() {
		var currentDate = new Date().toISOString().substr(0,10).replace(/-/g, ""); //YYYMMDD
		var matches = this.allMatches;
		matches = matches.filter(function(e) {
			return parseInt(e.matchDate) < parseInt(currentDate);
		});
		matches.sort(function(a, b) {
			return parseInt(a.matchDate) - parseInt(b.matchDate);
		});
		return matches[matches.length-1];
	};

	this.getNextScheduledMatchs = function() {
		var currentDate = new Date().toISOString().substr(0,10).replace(/-/g, ""); //YYYMMDD
		var matches = this.allMatches;
		matches = matches.filter(function(e) {
			return parseInt(e.matchDate) >= parseInt(currentDate);
		});
		matches.sort(function(a, b) {
			return parseInt(a.matchDate) - parseInt(b.matchDate);
		});
		return matches[0];
	};
}