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
}])
.directive("matchList", function() {
	return {
		restrict: 'E',
		scope: {
			matches : '=',
			type: '@'
		},
		templateUrl: 'template/match-list.html'
	};
})
.directive("svgSrc", function() {
	return {
		restrict: 'A',
		link: function(scope, element, attr) { //positional args. Not injected!
			var fallBack = attr.fallBack || 'png';
			var isSvgSupported = Modernizr.svg;
			element.attr('src', attr.svgSrc + "." + (isSvgSupported ? 'svg' : fallBack));
		},
		replace: false
	};
})
.filter('eedate', function($filter) {
	return function(date, format) {
		var parts = date.match(/(\d{4})-?(\d{2})-?(\d{2})/);
		if (parts) {
			return $filter('date')(new Date(parts[1], parts[2]-1, parts[3]), format);
		} else {
			return date;
		}
	};
});