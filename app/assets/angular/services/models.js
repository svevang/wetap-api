'use strict';

var weTap = angular.module('weTap');

weTap.factory('WaterFountain', ['$resource', function ($resource) {

  var waterFountainFactory = $resource('/api/v1/water_fountains/:id.json?public_token=:key', {id: '@id', key: window.public_token});

  // define properties to allow the app to use, for example, wf.latitude instead of wf.location.coordinates[1]
  _.each(["longitude", "latitude"], function(coordinate, ix) {
      Object.defineProperty(waterFountainFactory.prototype, coordinate, {
        get: function () {return this.location.coordinates[ix];},
        enumerable : true,
        configurable : true
      });
    });

  return waterFountainFactory;
}]);
