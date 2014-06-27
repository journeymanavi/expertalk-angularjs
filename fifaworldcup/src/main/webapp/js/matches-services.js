angular.module("matchesServices", [])
.factory("allMatchesService", ["$http", function($http) {
	var allMatchesService = {};

	allMatchesService.getMatchesSummary = function(callBack) {
		$http.get('api/matches')
		.success(function(response) {
			callBack(new MatchesSummary(response))
		});
	};

	return allMatchesService;
}]);