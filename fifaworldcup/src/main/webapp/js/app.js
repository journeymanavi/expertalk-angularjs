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
}])
.config(["$httpProvider", function($httpProvider) {
	$httpProvider.interceptors.push(['$q', '$location','$rootScope', function($q, $location, $rootScope) {
		return {
			'responseError' : function(rejection) {
				if(rejection.status == 401) {
					window.location.href = "/fifaworldcup/readytoplay";
				}
				return $q.reject(rejection);
			}
		}
	}]);
}]);