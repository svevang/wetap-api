'use strict';

var weTap = angular.module('weTap');

weTap.controller('WaterFountainIndexController', ['$scope', 'WaterFountain', function ($scope, WaterFountain) {
  // Grab all waterFountains from the server
  $scope.fountains = WaterFountain.query({bbox: "-122.442645,37.737684,-122.387714,37.814752"});

  // Destroy method for deleting a waterFountain
  $scope.destroy = function (index) {
    // Tell the server to remove the object
    WaterFountain.remove({id: $scope.fountains[index].id}, function () {
      // If successful, remove it from our collection
      //
      // NOTE: removedFountain and globalMarkerReference represent the same
      // fountain, but *sometimes* reference a different instance - especially
      // after panning around and zooming a bunch.
      var removedFountain = $scope.fountains.splice(index, 1)[0];
      var globalMarkerReference = window.fountainsOnMap[removedFountain.id];
      window.fountainLayerGroup.removeLayer(globalMarkerReference.markerLayer);
    });
  };
}]);

weTap.controller('WaterFountainCreateController', ['$scope', '$location', 'WaterFountain', function ($scope, $location, WaterFountain) {
  $scope.save = function () {
    // Create the waterFountain object to send to the back-end
    var waterFountain = new WaterFountain({
      water_fountain: {
        location: {
          type: "Point",
          coordinates: [$scope.waterFountain.longitude, $scope.waterFountain.latitude]
        }
      }
    });
    // Save the waterFountain object
    waterFountain.$save(function () {
      // redirect to the main page
      $location.path('/');
    }, function (response) {
      // send response objects to the view
      $scope.errors = response.data.errors;
    });
  };
}]);

// A controller to show the waterFountain in all its glory
weTap.controller('WaterFountainShowController', ['$scope', 'WaterFountain', '$routeParams', function ($scope, WaterFountain, $routeParams) {
  // Grab the waterFountain from the server
  $scope.waterFountain = WaterFountain.get({id: $routeParams.id});
  $scope.sites = [];
  // minimal set needed to initialize the map without errors
  $scope.map = {center: {latitude: 0, longitude: 0}, zoom: 0};

  $scope.$watch('waterFountain.id', function () {
    if ($scope.waterFountain.$resolved) {
      $scope.sites.push({
        latitude: $scope.waterFountain.latitude,
        longitude: $scope.waterFountain.longitude,
        options: {title: "Fountain: " + $scope.waterFountain.id}
      });
      $scope.map = {
        control: {},
        options: {
          streetViewControl: true,
          panControl: false,
          maxZoom: 20,
          minZoom: 3
        },
        center: {
          latitude: $scope.waterFountain.latitude,
          longitude: $scope.waterFountain.longitude
        },
        zoom: 18
      };
    }
  });

  _.each($scope.sites, function (site) {
    site.closeClick = function () {
      site.showWindow = false;
      $scope.$apply();
    };
    site.onClicked = function () {
      onMarkerClicked(site);
    };
  });

  $scope.isDefined = function (viewVar) {
    return angular.isDefined(viewVar);
  };
}]);
