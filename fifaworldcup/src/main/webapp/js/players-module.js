angular.module("playersModule", [])
.controller("playersController", function($scope, $http) {
	$http.get('api/players')
	.success(function(response) {
		$scope.players = response;
	});
});