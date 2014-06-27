angular.module("fifaworldcup", [
	"ngRoute",
	"matchesControllers",
	"teamsModule",
	"playersModule"
])
.config(["$routeProvider", function($routeProvider) {
	$routeProvider
	.when("/", {
		templateUrl: "template/home.html"
	})
	.when("/teams", {
		controller: "teamsController",
		templateUrl: "template/teams.html"
	})
	.when("/players", {
		controller: "playersController",
		templateUrl: "template/players.html"
	});
}]);