Ext.onReady(function() {
    var extent  = new OpenLayers.Bounds(-8256422,4949565,-8208878,4981592);

    options = {  maxExtent: new OpenLayers.Bounds(-180, -90, 180, 90)     };
    var options = {
projection: new OpenLayers.Projection("EPSG:900913"),
displayProjection: new OpenLayers.Projection("EPSG:4326"),
units: "m",
numZoomLevels:21,
maxResolution: 156543.0339,
maxExtent: new OpenLayers.Bounds(-20037508, -20037508, 20037508, 20037508.34)
};
 var mapnik = new OpenLayers.Layer.TMS(
                "OSM Mapnik",
                "http://tile.openstreetmap.org/",
                {   type: 'png', getURL: osm_getTileURL,
                    displayOutsideMaxExtent: true,
                    attribution: '<a href="http://www.openstreetmap.org/">OpenStreetMap</a>' }
            );

map = new OpenLayers.Map(options);

                map.addLayer(mapnik);
                
var mapPanel = new GeoExt.MapPanel({
                    region: 'center',
                    title: "Map",
                    map: map,
                    extent: extent//,
                    // layers: [layer]
                    // split: true
                });

var vp =  new Ext.Viewport({
layout: 'border',
items: [
  new Ext.BoxComponent({
    region: 'north',
    el: 'north',
    height: 74
}), {
  region: 'east',
  id: 'east-panel',
  width: 400,
  autoScroll: true,
  items: [
  {
title: 'Help',
id: 'help',
contentEl: 'helptext',
collapsible: true
                            }]
                        }, 
  mapPanel                       
    ]
});


});

