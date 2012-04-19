	 var warpedmap;
         var warped_wmslayer;
	 var maxOpacity = 1;
   var minOpacity = 0.1;

 
   function warpedinit(){
     OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
     OpenLayers.Util.onImageLoadErrorColor = "transparent";
     var options_warped = {
projection: new OpenLayers.Projection("EPSG:900913"),
            displayProjection: new OpenLayers.Projection("EPSG:4326"),
            units: "m",
            numZoomLevels:20,
            maxResolution: 156543.0339,
            maxExtent: new OpenLayers.Bounds(-20037508, -20037508,
                20037508, 20037508.34),
            controls: [
              new OpenLayers.Control.Attribution(),
            new OpenLayers.Control.LayerSwitcher(),
            new OpenLayers.Control.Navigation(),
            new OpenLayers.Control.PanZoomBar()
              ]
     };

   warpedmap = new OpenLayers.Map('warpedmap', options_warped);
   // create OSM layer
   mapnik3 = mapnik.clone();
   warpedmap.addLayer(mapnik3);
 
   nyc3 = nyc.clone();
   nyc3.setIsBaseLayer(true);
   warpedmap.addLayer(nyc3);

   ortho3 = ortho.clone();
   ortho3.setIsBaseLayer(true);
   warpedmap.addLayer(ortho3);

   for (var i =0; i < layers_array.length;i++){
   warpedmap.addLayer(get_map_layer(layers_array[i]));
   }

   var warped_wms_url = warpedwms_url;

   warped_wmslayer =  new OpenLayers.Layer.WMS
     ( "warped image",
       warped_wms_url,
       {format: 'image/png', status: 'warped'   },
       {         TRANSPARENT:'true', reproject: 'true'},
       { gutter: 15, buffer:0},
       { projection:"epsg:4326", units: "m"  }
     );
   var opacity = .7;
   warped_wmslayer.setOpacity(opacity);
   warped_wmslayer.setIsBaseLayer(false);
   warpedmap.addLayer(warped_wmslayer);

   jpl_wms3 = jpl_wms.clone();
   warpedmap.addLayer(jpl_wms3); 
  

   clipmap_bounds_merc  = new OpenLayers.Bounds();

   clipmap_bounds_merc  = cliplonLatToMercatorBounds(warped_bounds);

   warpedmap.zoomToExtent(clipmap_bounds_merc);

  //set up slider
  jQuery("#slider").slider({
    value: 100 * opacity,
    range: "min",
    slide: function(e, ui) {
    warped_wmslayer.setOpacity(ui.value / 100);
    OpenLayers.Util.getElement('opacity').value = ui.value;
      }
      });

  warpedmap.events.register("zoomend", mapnik3, function(){
      //console.log("zoomend");
      if (this.map.getZoom() > 18 && this.visibility == true){
        this.map.setBaseLayer(nyc3);
      } 
      
      });
}

function get_map_layer(layerid){
var newlayer_url = layer_baseurl + "/"+layerid;
var map_layer =  new OpenLayers.Layer.WMS
     ( "Layer "+ layerid,
       newlayer_url,
       {format: 'image/png'},
       {TRANSPARENT:'true', reproject: 'true'},
       { gutter: 15, buffer:0},
       { projection:"epsg:4326", units: "m"  }
     );
map_layer.setIsBaseLayer(false);
map_layer.visibility = false;

return map_layer;
}

  function changeOpacity(byOpacity) {
            var newOpacity = (parseFloat(OpenLayers.Util.getElement('opacity').value) + byOpacity).toFixed(1);
            newOpacity = Math.min(maxOpacity,
                                  Math.max(minOpacity, newOpacity));
            OpenLayers.Util.getElement('opacity').value = newOpacity;
            wmslayer.setOpacity(newOpacity);
        }



function mercatorToLonLat(merc) {
	 var lon = (merc.lon / 20037508.34) * 180;
	 var lat = (merc.lat / 20037508.34) * 180;

	 lat = 180/Math.PI * (2 * Math.atan(Math.exp(lat * Math.PI / 180)) - Math.PI / 2);

 return new OpenLayers.LonLat(lon, lat);
}

function lonLatToMercator(ll) {
	 var lon = ll.lon * 20037508.34 / 180;
	 var lat = Math.log(Math.tan((90 + ll.lat) * Math.PI / 360)) / (Math.PI / 180);

	 lat = lat * 20037508.34 / 180;

	 return new OpenLayers.LonLat(lon, lat);
}

function cliplonLatToMercatorBounds(llbounds){
var proj = new OpenLayers.Projection("EPSG:4326");
var newbounds = llbounds.transform(proj, warpedmap.getProjectionObject());

return newbounds;

} 
