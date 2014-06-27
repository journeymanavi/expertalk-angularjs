angular.module("matchesControllers", ["matchesServices"])
.controller("matchesSummaryController", ["$scope", "allMatchesService",
	function($scope, allMatchesService) {
		// call service to get model
		allMatchesService.getMatchesSummary(function(matchesSummary) {
			// set model in scope to share with view
			$scope.matchesSummary = matchesSummary;
		});
	}
]);