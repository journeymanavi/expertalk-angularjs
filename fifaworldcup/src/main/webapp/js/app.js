angular.module("fifaworldcup", ["ngRoute"])
.config(["$routeProvider", function($routeProvider) {
	$routeProvider
	.when("/", {
		templateUrl: "template/home.html"
	})
	.when("/teams", {
		templateUrl: "template/teams.html"
	})
	.when("/players", {
		templateUrl: "template/players.html"
	});
}])
.controller("matchesController", function($scope, $http) {
	$http.get('api/matches')
	.success(function(response) {
		$scope.matchesByDate = response;

		$scope.getLatestResults = function() {
			var currentDate = new Date().toISOString().substr(0,10).replace(/-/g, ""); //YYYMMDD
			var matches = $scope.matchesByDate;
			matches = matches.filter(function(e) {
				return parseInt(e.matchDate) < parseInt(currentDate);
			});
			matches.sort(function(a, b) {
				return parseInt(a.matchDate) - parseInt(b.matchDate);
			});
			return matches[matches.length-1];
		};

		$scope.getNextScheduledMatchs = function() {
			var currentDate = new Date().toISOString().substr(0,10).replace(/-/g, ""); //YYYMMDD
			var matches = $scope.matchesByDate;
			matches = matches.filter(function(e) {
				return parseInt(e.matchDate) >= parseInt(currentDate);
			});
			matches.sort(function(a, b) {
				return parseInt(a.matchDate) - parseInt(b.matchDate);
			});
			return matches[0];
		};
	});
})
.controller("teamsController", function($scope, $http) {
	$http.get('api/teams')
	.success(function(response) {
		$scope.teams = response;
	});
})
.controller("playersController", function($scope, $http) {
	$http.get('api/players')
	.success(function(response) {
		$scope.players = response;
	});
});