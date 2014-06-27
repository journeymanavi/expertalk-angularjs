angular.module("teamsModule", [])
.controller("teamsController", function($scope, $http) {
	$http.get('api/teams')
	.success(function(response) {
		$scope.teams = response;
	});
});