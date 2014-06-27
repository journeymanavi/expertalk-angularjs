angular.module("playersModule", [])
.controller("playersController", function($scope, $http) {
	$scope.players = {status: 'loading'};
	$http.get('api/players')
	.success(function(response) {
		$scope.players = response;
		$scope.players.status = "success";
	})
	.error(function(response) {
		$scope.players = {status : "error"};
	});
});