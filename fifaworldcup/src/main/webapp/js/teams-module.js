angular.module("teamsModule", [])
.controller("teamsController", function($scope, $http) {
	$scope.teams = {status: 'loading'};
	$http.get('api/teams')
	.success(function(response) {
		$scope.teams = response;
		$scope.teams.status = "success";
	})
	.error(function(response) {
		$scope.teams = {status : "error"};
	});
});