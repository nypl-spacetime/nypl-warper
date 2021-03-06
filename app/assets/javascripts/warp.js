var temp_gcp_status = false;
var from_templl;
var to_templl;
var warped_layer; //the warped wms layer
var to_layer_switcher;
var navig;
var navigFrom;
var to_vectors;
var from_vectors;
var active_to_vectors;
var active_from_vectors;

if(typeof maps === 'undefined'){
	var maps = {};
}

maps['warp'] = {};
maps['from_map'] = {};
maps['to_map'] = {};

maps['from_map'].keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' });
maps['to_map'].keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' });

maps['from_map'].newZoom = null;
maps['from_map'].oldZoom = null;
maps['from_map'].resolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18]

maps['to_map'].newZoom = null;
maps['to_map'].oldZoom = null;
maps['to_map'].resolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18]

maps['warp'].active = false;
maps['warp'].deactivate = function(){
  //console.log('warp deactivate');
  maps['from_map'].keyboard.deactivate();
  maps['to_map'].keyboard.deactivate();

  maps['from_map'].active = false;
  maps['to_map'].active = false;
  maps['warp'].active = false;
}
maps['warp'].activate = function(){
  //console.log('warp activate');
  
  maps['from_map'].keyboard.activate();
  maps['to_map'].keyboard.activate();

  maps['from_map'].active = true;
  maps['to_map'].active = true;
  maps['warp'].active = true;
  warp_updateSize();
  currentMaps = ['from_map', 'to_map'];
}



///////////////////////////////////////////////////////////////////////////////////////////
//
// INIT
//
///////////////////////////////////////////////////////////////////////////////////////////
function init() {

  from_map = new OpenLayers.Map('from_map', {
    controls: [new OpenLayers.Control.PanZoomBar(), maps['from_map'].keyboard],
    maxExtent: new OpenLayers.Bounds(0, 0, image_width, image_height),
    resolutions: maps['from_map'].resolutions
  });

  maps['from_map'].map = from_map;

  var image = new OpenLayers.Layer.WMS(title,
          wms_url, {
            format: 'image/png',
            status: 'unwarped'},
  {
    transitionEffect: 'resize'
  });

  from_map.addLayer(image);

  if (!from_map.getCenter()) {
    from_map.zoomToMaxExtent();
  }

  OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
  OpenLayers.Util.onImageLoadErrorColor = "transparent";

  to_layer_switcher = new OpenLayers.Control.LayerSwitcher();
  var options = {
    projection: new OpenLayers.Projection("EPSG:900913"),
    displayProjection: new OpenLayers.Projection("EPSG:4326"),
    units: "m",
    numZoomLevels: 22,
    maxResolution: 156543.0339,
    maxExtent: new OpenLayers.Bounds(-20037508, -20037508, 20037508, 20037508.34),
    controls: [new OpenLayers.Control.Attribution(), to_layer_switcher, new OpenLayers.Control.PanZoomBar()]
  };

  to_map = new OpenLayers.Map('to_map', options);
  maps['to_map'].map = to_map;

  warped_layer = new OpenLayers.Layer.WMS.Untiled("warped map", wms_url, {
    format: 'image/png',
    status: 'warped'},
  {TRANSPARENT: 'true', reproject: 'true'},
  {gutter: 15, buffer: 0},
  {projection: "epsg:4326", units: "m"}
  );


  var warpedOpacity = 0.6;
  warped_layer.setOpacity(warpedOpacity);
  warped_layer.setVisibility(false);
  warped_layer.setIsBaseLayer(false);
  to_map.addLayer(warped_layer);

  to_map.addLayer(mapnik);


  for (var i = 0; i < layers_array.length; i++) {
    to_map.addLayer(get_map_layer(layers_array[i]));
  }


  ny_2014.setVisibility(false);
  to_map.addLayer(ny_2014);

  if (map_has_bounds) {
    map_bounds_merc = new OpenLayers.Bounds();
    map_bounds_merc = lonLatToMercatorBounds(map_bounds);

    to_map.zoomToExtent(map_bounds_merc);

  } else {
    //set to the world
    to_map.setCenter(lonLatToMercator(new OpenLayers.LonLat(0.0, 0.0)), 10);
  }

  //style for the active, temporary vector marker, the one the user actually adds themselves,
  var active_style = OpenLayers.Util.extend({},
          OpenLayers.Feature.Vector.style['default']);
  active_style.graphicOpacity = 1;
  active_style.graphicWidth = 14;
  active_style.graphicHeight = 22;
  active_style.graphicXOffset = -(active_style.graphicWidth / 2);
  active_style.graphicYOffset = -active_style.graphicHeight;
  active_style.externalGraphic = icon_imgPath + "AQUA.png";

  to_vectors = new OpenLayers.Layer.Vector("To vector markers");
  to_vectors.displayInLayerSwitcher = false;

  from_vectors = new OpenLayers.Layer.Vector("From vector markers");
  from_vectors.displayInLayerSwitcher = false;

  active_to_vectors = new OpenLayers.Layer.Vector("active To vector markers", {style: active_style});
  active_to_vectors.displayInLayerSwitcher = false;

  active_from_vectors = new OpenLayers.Layer.Vector("active from vector markers", {style: active_style});
  active_from_vectors.displayInLayerSwitcher = false;

  to_map.addLayers([to_vectors, active_to_vectors]);
  from_map.addLayers([from_vectors, active_from_vectors]);
  //fix for dragging bug
  //  OpenLayers.Control.DragFeature.prototype.upFeature = function() {};
  //fix
  var to_panel = new OpenLayers.Control.Panel(
          {displayClass: 'olControlEditingToolbar'}
  );
  var dragMarker = new OpenLayers.Control.DragFeature(to_vectors,
          {displayClass: 'olControlDragFeature', title: 'Drag Control Point (d)'});
  dragMarker.onComplete = function(feature) {
    saveDraggedMarker(feature);
  };

  var drawFeatureTo = new OpenLayers.Control.DrawFeature(active_to_vectors, OpenLayers.Handler.Point,
          {displayClass: 'olControlDrawFeaturePoint', title: 'Add Control Point (p)', handlerOptions: {style: active_style}});
  drawFeatureTo.featureAdded = function(feature) {
    newaddGCPto(feature);
  };

  var drawFeatureFrom = new OpenLayers.Control.DrawFeature(active_from_vectors, OpenLayers.Handler.Point,
          {displayClass: 'olControlDrawFeaturePoint', title: 'Add Control Point (p)', handlerOptions: {style: active_style}});
  drawFeatureFrom.featureAdded = function(feature) {
    newaddGCPfrom(feature);
  };

  var from_panel = new OpenLayers.Control.Panel(
          {displayClass: 'olControlEditingToolbar'}
  );
  var dragMarkerFrom = new OpenLayers.Control.DragFeature(from_vectors,
          {displayClass: 'olControlDragFeature', title: 'Drag Control Point (d)'});
  dragMarkerFrom.onComplete = function(feature) {
    saveDraggedMarker(feature);
  };

  navig = new OpenLayers.Control.Navigation({title: "Move Around Map (m)", zoomWheelEnabled: true});
  navigFrom = new OpenLayers.Control.Navigation({title: "Move Around Map (m)", zoomWheelEnabled: true});

  to_panel.addControls([navig, dragMarker, drawFeatureTo]);
  to_map.addControl(to_panel);

  from_panel.addControls([navigFrom, dragMarkerFrom, drawFeatureFrom]);
  from_map.addControl(from_panel);

  //we'll add generic navigation controls so we can zoom whilst addingd
  to_map.addControl(new OpenLayers.Control.Navigation({zoomWheelEnabled: true}));
  from_map.addControl(new OpenLayers.Control.Navigation({zoomWheelEnabled: true}));

  navig.activate();
  navigFrom.activate();

  joinControls(dragMarker, dragMarkerFrom);
  joinControls(navig, navigFrom);
  joinControls(drawFeatureTo, drawFeatureFrom);


  // keyboard shortcuts for switching tools
  var keyboardControl = new OpenLayers.Control();  
  var control = new OpenLayers.Control();
  var callbacks = { keydown: function(evt) {
    //console.log("You pressed a key: " + evt.keyCode);
    if (maps['warp'].active){
      switch(evt.keyCode) {
      	  case 65: // a
      	  	toggleWarpMap('from_map');
      	  	break;
      	  case 90: // z
      	  	toggleWarpMap('to_map');
      	  	break;
          case 80: // p
              switchTool('pin');
              break;
          case 68: // d
              switchTool('drag');
              break;
          case 77: // m
              switchTool('move');
              break;

          default:
            //console.log('default')
        }
      }
    }
  };
        
  var options = {};
  var handler = new OpenLayers.Handler.Keyboard(control, callbacks, options);

  handler.activate();
  to_map.addControl(keyboardControl);
  to_map.addControl(maps['to_map'].keyboard);


  function switchTool(newTool){
    // first deactivate everything
    from_map.controls[2].deactivate();
    from_map.controls[3].deactivate();
    from_map.controls[4].deactivate();

    switch(newTool) {
        case 'pin':
            from_map.controls[4].activate();
            break;
        case 'drag':
            from_map.controls[3].activate();
            break;
        case 'move':
            from_map.controls[2].activate();
            break;
        default: 
          //console.log('switchTool ' + newTool + ' not matched');
    }
  }




    to_map.events.register("zoomend", to_map, function(){
        //console.log('zoomend -- to_map.zoom: ' + to_map.zoom + ' newZoom: ' + newZoom);
        if (to_map.zoom < maps['to_map'].newZoom){
          //console.log('adding .5 to accommediate for the math.floor -- to_map.zoom: ' + to_map.zoom + ' newZoom: ' + newZoom);
          maps['to_map'].newZoom = to_map.zoom + 0.5;
        } else {
          maps['to_map'].newZoom = to_map.zoom;
        }
    });

    from_map.events.register("zoomend", from_map, function(){
        //console.log('zoomend -- from_map.zoom: ' + from_map.zoom + ' newZoom: ' + newZoom);
        if (from_map.zoom < maps['from_map'].newZoom){
          //console.log('adding .5 to accommediate for the math.floor -- from_map.zoom: ' + from_map.zoom + ' newZoom: ' + newZoom);
          maps['from_map'].newZoom = from_map.zoom + 0.5;
        } else {
          maps['from_map'].newZoom = from_map.zoom;
        }
    });


  //set up jquery slider for warped layer
  jQuery("#warped-slider").slider({
    value: 100 * warpedOpacity,
    range: "min",
    slide: function(e, ui) {
      warped_layer.setOpacity(ui.value / 100);
    }
  });
  jQuery("#warped-slider").hide();
  warped_layer.events.register('visibilitychanged', this, function(layer) {
    if (layer.object.getVisibility() === true) {
      jQuery("#warped-slider").show();
    } else {
      jQuery("#warped-slider").hide();
    }
  });
  
	 /*
	  // switch between maps based upon zoom level
	  to_map.events.register("zoomend", mapnik, function () {
	    if (this.map.getZoom() > 18 && this.visibility == true) {
	      this.map.setBaseLayer(ny_2014);
	    }
	  });
	  
	   to_map.events.register("zoomend", ny_2014, function () {
	    if (this.map.getZoom() < 15 && this.visibility == true) {
	      this.map.setBaseLayer(mapnik);
	    }
	  });
	*/


  // setup resize
  window.addEventListener("resize", warp_updateSize);
  warp_updateSize();
  from_map.zoomToMaxExtent();

} // end init


  function toggleWarpMap(mapName){

  	if (typeof maps['from_map'] != 'undefined' && typeof maps['to_map'] != 'undefined'){

  		if (maps[mapName].active){
  			maps[mapName].active = false;
  			maps[mapName].keyboard.deactivate();

  			// remove map from control array
	  		var newMaps = [];
	  		for (var i = 0; i < currentMaps.length; i++) {
	  			if (currentMaps[i] != mapName){
	  				newMaps.push(currentMaps[i]);
	  			}
	  		};
	  		currentMaps = newMaps;

  		} else {
  			maps[mapName].active = true;
  			maps[mapName].keyboard.activate();

  			// add map from control array if not present
	  		var matched = false;
	  		for (var i = 0; i < currentMaps.length; i++) {
	  			if (currentMaps[i] === mapName){
	  				matched = true;
	  			}
	  		};

	  		if (matched === false){
	  			currentMaps.push(mapName);
	  		}
  		}

  		console.log(mapName + ".active is now " + maps[mapName].active );

  		// check if both have been deactivated in which case reactive both
  		// because deactivating both maps will appear to be a bug
  		if (!maps['from_map'].active && !maps['to_map'].active){
  			console.log('automatically reenabling both maps when both have been disabled')
  			maps['from_map'].keyboard.activate();
  			maps['from_map'].active = true;
  			maps['to_map'].keyboard.activate();
  			maps['to_map'].active = true;
  			currentMaps = ['from_map', 'to_map'];
  		}
  	}

  }

  function enableWarpMap(mapName){
  	//console.log('enableWarpMap: ' + mapName);

  	if (typeof maps['from_map'] != 'undefined' && typeof maps['to_map'] != 'undefined'){

  		if (mapName === 'from_map'){
  			maps['from_map'].active = true;
  			maps['from_map'].keyboard.activate();

  			maps['to_map'].active = false;
  			maps['to_map'].keyboard.deactivate();

  			currentMaps = ['from_map']
  		} else if (mapName === 'to_map'){
  			maps['from_map'].active = false;
  			maps['from_map'].keyboard.deactivate();

  			maps['to_map'].active = true;
  			maps['to_map'].keyboard.activate();

  			currentMaps = ['to_map']
  		} else if (mapName === 'both'){
  			maps['from_map'].active = true;
  			maps['from_map'].keyboard.activate();

  			maps['to_map'].active = true;
  			maps['to_map'].keyboard.activate();

  			currentMaps = ['to_map', 'from_map'];
  		}

  	}

  }




function joinControls(first, second) {
  first.events.register("activate", first, function() {
    second.activate();
  });
  first.events.register("deactivate", first, function() {
    second.deactivate();
  });
  second.events.register("activate", second, function() {
    first.activate();
  });
  second.events.register("deactivate", second, function() {
    first.deactivate();
  });
}

function get_map_layer(layerid) {
  var newlayer_url = layer_baseurl + "/" + layerid;
  var map_layer = new OpenLayers.Layer.WMS
          ("Layer " + layerid,
                  newlayer_url,
                  {format: 'image/png'},
          {TRANSPARENT: 'true', reproject: 'true'},
          {gutter: 15, buffer: 0},
          {projection: "epsg:4326", units: "m"}
          );
  map_layer.setIsBaseLayer(false);
  map_layer.visibility = false;

  return map_layer;
}


var moving = false;
var origXYZ = new Object();

function moveStart(mapEvent) {
  var passiveMap;
  var activeMap;
  if (this == 1) {
    activeMap = from_map;
    passiveMap = to_map;
  } else {
    activeMap = to_map;
    passiveMap = from_map;
  }
  var cent = activeMap.getCenter();
  origXYZ.lonlat = cent;
  origXYZ.zoom = activeMap.zoom;
}


function moveEnd(mapEvent) {
  if (moving) {
    return;
  }
  moving = true;
  var passiveMap;
  var activeMap;
  if (this == 1) {
    activeMap = from_map;
    passiveMap = to_map;
  } else {
    activeMap = to_map;
    passiveMap = from_map;
  }
  var newZoom = passiveMap.zoom;
  if (origXYZ.zoom != activeMap.zoom) {
    diffzoom = origXYZ.zoom - activeMap.zoom;
    newZoom = passiveMap.zoom - diffzoom;
  }
  var origPixel = activeMap.getPixelFromLonLat(origXYZ.lonlat);
  var newPixel = activeMap.getPixelFromLonLat(activeMap.getCenter());
  var difx = origPixel.x - newPixel.x;
  var dify = origPixel.y - newPixel.y;
  var passCen = passiveMap.getPixelFromLonLat(passiveMap.getCenter());
  passiveMap.setCenter(passiveMap.getLonLatFromPixel(
          new OpenLayers.Pixel(passCen.x - difx, passCen.y - dify)), newZoom, false, false);

  moving = false;

}
var mapLinked = false;
function toggleJoinLinks() {
  //TODO change the icon
  if (mapLinked === true) {
    mapLinked = false;
    document.getElementById('link-map-button').className = 'link-map-button-off';
  } else {
    mapLinked = true;
    document.getElementById('link-map-button').className = 'link-map-button-on';
  }
  if (mapLinked === true) {
    from_map.events.register("moveend", 1, moveEnd);
    to_map.events.register("moveend", 0, moveEnd);
    from_map.events.register("movestart", 1, moveStart);
    to_map.events.register("movestart", 0, moveStart);
  } else {
    from_map.events.unregister("moveend", 1, moveEnd);
    to_map.events.unregister("moveend", 0, moveEnd);
    from_map.events.unregister("movestart", 1, moveStart);
    to_map.events.unregister("movestart", 0, moveStart);
  }
}

function gcp_notice(text) {
  //jquery effect
  jqHighlight('rectifyNotice');
  notice = document.getElementById('gcp_notice');
  notice.innerHTML = text;
}

function update_gcp_field(gcp_id, elem) {
  var id = gcp_id;
  var value = elem.value;
  var attrib = elem.id.substring(0, (elem.id.length - (id + "").length));
  var url = gcp_update_field_url + "/" + id;

  jQuery('#spinner').show();
  gcp_notice('Updating...');

  var request = jQuery.ajax({
    type: "PUT",
    url: url,
    data: {authenticity_token: encodeURIComponent(window._token), attribute: attrib, value: value}}
  ).success(function() {
    gcp_notice("Control Point updated!");
    move_map_markers(gcp_id, elem);
  }).done(function() {
    jQuery('#spinner').hide();
  }).fail(function() {
    gcp_notice("Had trouble updating that point with the server. Try again?");
    elem.value = value;
  });
}

function update_gcp(gcp_id, listele) {
  var id = gcp_id;
  var url = gcp_update_url + "/" + id;

  for (i = 0; i < listele.childNodes.length; i++) {
    listtd = listele.childNodes[i]; //td
    for (e = 0; e < listtd.childNodes.length; e++) {

      listItem = listtd.childNodes[e];//input
      if (listItem.id == "x" + gcp_id) {
        x = listItem.value;
      }
      if (listItem.id == "y" + gcp_id) {
        y = listItem.value;
      }
      if (listItem.id == "lon" + gcp_id) {
        lon = listItem.value;
      }
      if (listItem.id == "lat" + gcp_id) {
        lat = listItem.value;
      }

    }
  }
  gcp_notice('Updating...');
  jQuery('#spinner').show();
  
  var request = jQuery.ajax({
    type: "PUT",
    url: url,
    data: {authenticity_token: encodeURIComponent(window._token), x: x, y: y, lon: lon, lat: lat}}
  ).success(function() {
    gcp_notice("Control Point updated!");
  }).done(function() {
    jQuery('#spinner').hide();
  }).fail(function() {
    gcp_notice("Had trouble updating that point with the server. Try again?");
    elem.value = value;
  });

}

function move_map_markers(gcp_id, elem) {
  var avalue = elem.value;
  var attrib = elem.id;
  trele = elem.parentNode.parentNode; //input>td>tr
  //get the other siblings next door to this one.
  for (i = 0; i < trele.childNodes.length; i++) {
    trchild = trele.childNodes[i]; //tds
    for (e = 0; e < trchild.childNodes.length; e++) {

      inp = trchild.childNodes[e]; //inputs
      if (inp.id == 'x' + gcp_id) {
        x = inp.value;
      }
      if (inp.id == 'y' + gcp_id) {
        y = image_height - inp.value;
      }
      if (inp.id == 'lon' + gcp_id) {
        tlon = inp.value;
      }
      if (inp.id == 'lat' + gcp_id) {
        tlat = inp.value;
      }
    }
  }

  if (attrib == 'x' + gcp_id || attrib == 'y' + gcp_id) {
    var frommark;
    for (var a = 0; a < from_vectors.features.length; a++) {
      if (from_vectors.features[a].gcp_id == gcp_id) {
        frommark = from_vectors.features[a];
      }//if
    } //for
    if (attrib == 'x' + gcp_id) {
      x = avalue;
    }
    if (attrib == 'y' + gcp_id) {
      y = image_height - avalue;
    }
    //frommark.geometry.move(new OpenLayers.LonLat(x, y));
    frommark.geometry.x = x;
    frommark.geometry.y = y;
    frommark.geometry.clearBounds();
    frommark.layer.drawFeature(frommark);
  }

  else if (attrib == 'lon' + gcp_id || attrib == 'lat' + gcp_id) {
    var tomark;
    for (var b = 0; b < to_vectors.features.length; b++) {
      if (to_vectors.features[b].gcp_id == gcp_id) {
        tomark = to_vectors.features[b];
      } //if
    }//for
    if (attrib == 'lon' + gcp_id) {
      tlon = avalue;
    }
    if (attrib == 'lat' + gcp_id) {
      tlat = avalue;
    }

    hacklonlat = lonLatToMercator(new OpenLayers.LonLat(tlon, tlat));
    tomark.geometry.x = hacklonlat.lon;
    tomark.geometry.y = hacklonlat.lat;
    tomark.geometry.clearBounds();
    tomark.layer.drawFeature(tomark);
  }
}

//when a vector marker is dragged, update values on form and save
function saveDraggedMarker(feature) {

  var listele = document.getElementById("gcp" + feature.gcp_id); //listele is a tr
  for (i = 0; i < listele.childNodes.length; i++) {
    listtd = listele.childNodes[i];//listtd is a td

    for (e = 0; e < listtd.childNodes.length; e++) {
      listItem = listtd.childNodes[e]; //listitem is the input field

      if (feature.layer == from_vectors) {
        if (listItem.id == "x" + feature.gcp_id) {
          listItem.value = feature.geometry.x;
        }
        if (listItem.id == "y" + feature.gcp_id) {
          listItem.value = image_height - feature.geometry.y;
        }
      }
      if (feature.layer == to_vectors) {
        var merc = new OpenLayers.LonLat(feature.geometry.x, feature.geometry.y);
        var vll = mercatorToLonLat(merc);
        if (listItem.id == "lon" + feature.gcp_id) {
          listItem.value = vll.lon;
        }
        if (listItem.id == "lat" + feature.gcp_id) {
          listItem.value = vll.lat;
        }
      }
    }//for
  }//for
  update_gcp(feature.gcp_id, listele);
}

function save_new_gcp(x, y, lon, lat) {

  url = gcp_add_url;
  gcp_notice("Adding...");
  jQuery('#spinner').show();
  
  var request = jQuery.ajax({
    type: "POST",
    url: url,
    data: {authenticity_token: encodeURIComponent(window._token), x: x, y: y, lat: lat, lon: lon}}
  ).done(function() {
    update_row_numbers();
    jQuery('#spinner').hide();
  }).fail(function() {
    gcp_notice("Had trouble saving that point to the server. Try again?");
  });
  
}


function update_rms(new_rms) {
  fi = document.getElementById('errortitle');
  fi.value = "Error(" + new_rms + ")";
}


function delete_markers(gcp_id) {
  for (var a = 0; a < from_vectors.features.length; a++) {

    if (from_vectors.features[a].gcp_id == gcp_id) {

      del_from_mark = from_vectors.features[a];
      del_to_mark = to_vectors.features[a];

      from_vectors.destroyFeatures([del_from_mark]);
      to_vectors.destroyFeatures([del_to_mark]);
    }
  }
  update_row_numbers();
}


//called after initial populate, each delete, and each add
function update_row_numbers() {
  for (var a = 0; a < from_vectors.features.length; a++) {
    temp_marker = from_vectors.features[a];
    li_ele = document.getElementById("gcp" + temp_marker.gcp_id);

    ////////////////
    inputs = li_ele.getElementsByTagName("input");
    for (var b = 0; b < inputs.length; b++) {
      if (inputs[b].name == "error" + temp_marker.gcp_id) {
        error = inputs[b].value;
      }
    }
    var color = getColorString(error);
    updateGcpColor(from_vectors.features[a], color);
    updateGcpColor(to_vectors.features[a], color);
    ////////////

    span_ele = li_ele.getElementsByTagName("span");
    if (span_ele[0].className == "marker_number") {
      var thishtml = "<img src='" + icon_imgPath + (temp_marker.id_index + 1) + color + ".png' />";
      span_ele[0].innerHTML = thishtml;
    }

    if (span_ele[1] != undefined && span_ele[1].className == "ui-button-text") {
      var thishtml = "delete point " + (temp_marker.id_index + 1) + "";
      span_ele[1].innerHTML = thishtml;
    }

    jQuery('.marker_number').click(function(){
      var markerID = jQuery(this).parent().find('input').val();
      centerOnMarker(markerID);
    })
  

  }
  redrawGcpLayers();
}



function redrawGcpLayers() {
  from_vectors.redraw();
  to_vectors.redraw();
}


function updateGcpColor(marker, color) {
  marker.style.externalGraphic = icon_imgPath + (marker.id_index + 1) + color + '.png';
}



//blue, green, orange, red
function getColorString(error) {
  var colorString = "";
  if (error < 5) {
    colorString = "";
  } else if (error >= 5 && error < 10) {
    colorString = "_green";
  } else if (error >= 10 && error < 50) {
    colorString = "_orange";
  } else if (error >= 50) {
    colorString = "_red";
  }
  //TODO
  return colorString;
  //return "";
}


function populate_gcps(gcp_id, img_lon, img_lat, dest_lon, dest_lat, error) {
  //console.log('populate_gcps: ' + gcp_id);
  error = typeof (error) != "undefined" ? error : 0;
  var color = getColorString(error);

  //x y lon lat
  index = gcp_markers.length;
  gcp_markers.push(index); // 0 to 7 or so
  got_lon = img_lon;
  got_lat = image_height - img_lat;
  add_gcp_marker(from_vectors, new OpenLayers.LonLat(got_lon, got_lat), false, index, gcp_id, color);

  add_gcp_marker(to_vectors, lonLatToMercator(new OpenLayers.LonLat(dest_lon, dest_lat)), false, index, gcp_id, color);
}


function set_gcp() {
  check_if_gcp_ready();
  if (!temp_gcp_status) {
    alert("You have to add a new control point on each map before pressing this button.");
    return false;
  } else {
    var from_lonlat = from_templl;
    var to_lonlat = mercatorToLonLat(to_templl);

    var img_lon = from_lonlat.lon;
    var img_lat = from_lonlat.lat;

    var proper_img_lat = image_height - img_lat;
    var proper_img_lon = img_lon;
    console.log('proper_img_lon: ' + proper_img_lon + ' proper_img_lat: ' + proper_img_lat);

    save_new_gcp(proper_img_lon, proper_img_lat, to_lonlat.lon, to_lonlat.lat);

    active_from_vectors.destroyFeatures();
    active_to_vectors.destroyFeatures();
  }
}



function add_gcp_marker(markers_layer, lonlat, is_active_marker, id_index, gcp_id, color) {
  color = typeof (color) != "undefined" ? color : "";
  id_index = typeof (id_index) != 'undefined' ? id_index : -2;
  var style_mark = OpenLayers.Util.extend({},
          OpenLayers.Feature.Vector.style['default']);
  style_mark.graphicOpacity = 1;
  style_mark.graphicWidth = 14;
  style_mark.graphicHeight = 22;
  style_mark.graphicXOffset = -(style_mark.graphicWidth / 2);
  style_mark.graphicYOffset = -style_mark.graphicHeight;
  if (is_active_marker === true) {
    active_style.externalGraphic = icon_imgPath + "AQUA.png";
  } else {
    style_mark.externalGraphic = icon_imgPath + (id_index + 1) + color + '.png';
  }
  var thisVector = new OpenLayers.Geometry.Point(lonlat.lon, lonlat.lat);
  var pointFeature = new OpenLayers.Feature.Vector(thisVector, null, style_mark);
  pointFeature.id_index = id_index;
  pointFeature.gcp_id = gcp_id;

  markers_layer.addFeatures([pointFeature]);

  resetHighlighting();
}



function addLayerToDest(frm) {
  num = frm.layer_num.value;
  new_wms_url = empty_wms_url + '/' + num;

  new_warped_layer = new OpenLayers.Layer.WMS.Untiled("warped map " + num, new_wms_url, {
    format: 'image/png',
    status: 'warped'
  },
  {
    TRANSPARENT: 'true',
    reproject: 'true'
  },
  {
    gutter: 15,
    buffer: 0
  },
  {
    projection: "epsg:4326",
    units: "m"
  });
  new_warped_layer.setOpacity(0.6);
  new_warped_layer.setVisibility(true);
  new_warped_layer.setIsBaseLayer(false);
  to_map.addLayer(new_warped_layer);

  to_layer_switcher.maximizeControl();

  jQuery('#add_layer').hide();

}

function show_warped_map() {
  warped_layer.setVisibility(true);
  warped_layer.mergeNewParams({'random': Math.random()});
  warped_layer.redraw(true);
  to_layer_switcher.maximizeControl();

  //cross tab issue - reloads the rectified map in the preview tab if its there
  if (typeof warpedmap != 'undefined' && typeof warped_wmslayer != 'undefined') {
    warped_wmslayer.mergeNewParams({'random': Math.random()});
    warped_wmslayer.redraw(true);
  }
}


function check_if_gcp_ready() {
  if (active_to_vectors.features.length > 0 && active_from_vectors.features.length > 0) {
    temp_gcp_status = true;
    document.getElementById("addPointDiv").className = "addPointHighlighted";
    document.getElementById("GcpButton").disabled = false;
  } else {
    temp_gcp_status = false;
  }
}

function newaddGCPto(feat) {
  if (active_to_vectors.features.length > 1) {
    var to_destroy = new Array();
    for (var a = 0; a < active_to_vectors.features.length; a++) {
      if (active_to_vectors.features[a] != feat) {
        to_destroy.push(active_to_vectors.features[a]);
      }
    }
    active_to_vectors.destroyFeatures(to_destroy);
  }
  var lonlat = new OpenLayers.LonLat(feat.geometry.x, feat.geometry.y);
  highlight(to_map.div);

  to_templl = lonlat;
  check_if_gcp_ready();
}

function newaddGCPfrom(feat) {
  if (active_from_vectors.features.length > 1) {
    var to_destroy = new Array();
    for (var a = 0; a < active_from_vectors.features.length; a++) {
      if (active_from_vectors.features[a] != feat) {
        to_destroy.push(active_from_vectors.features[a]);
      }
    }
    active_from_vectors.destroyFeatures(to_destroy);
  }
  var lonlat = new OpenLayers.LonLat(feat.geometry.x, feat.geometry.y);
  //console.log('feat.geometry.x: ' + feat.geometry.x + ' feat.geometry.y: ' + feat.geometry.y + ' lonlat: ' + lonlat);
  highlight(from_map.div);

  from_templl = lonlat;
  check_if_gcp_ready();
}

function addLayerToDest(frm) {
  num = frm.layer_num.value;
  new_wms_url = empty_wms_url + '/' + num;

  new_warped_layer = new OpenLayers.Layer.WMS.Untiled("warped map " + num, new_wms_url,
          {format: 'image/png', status: 'warped'},
  {TRANSPARENT: 'true', reproject: 'true'},
  {gutter: 15, buffer: 0},
  {projection: "epsg:4326", units: "m"}
  );
  new_warped_layer.setOpacity(.6);
  new_warped_layer.setVisibility(true);
  new_warped_layer.setIsBaseLayer(false);
  to_map.addLayer(new_warped_layer);

  to_layer_switcher.maximizeControl();

  jQuery('#add_layer').hide();

}

function resetHighlighting() {
  to_map.div.className = "map-off";
  from_map.div.className = "map-off";
  document.getElementById("addPointDiv").className = "addPoint";
  document.getElementById("GcpButton").disabled = true;
}

function highlight(thingToHighlight) {
  thingToHighlight.className = "highlighted";
}


//TODO deprecate these transform methods to use OL's transform command
function mercatorToLonLat(merc) {
  var lon = (merc.lon / 20037508.34) * 180;
  var lat = (merc.lat / 20037508.34) * 180;

  lat = 180 / Math.PI * (2 * Math.atan(Math.exp(lat * Math.PI / 180)) - Math.PI / 2);

  return new OpenLayers.LonLat(lon, lat);
}

function lonLatToMercator(ll) {
  var lon = ll.lon * 20037508.34 / 180;
  var lat = Math.log(Math.tan((90 + ll.lat) * Math.PI / 360)) / (Math.PI / 180);

  lat = lat * 20037508.34 / 180;

  return new OpenLayers.LonLat(lon, lat);
}


function lonLatToMercatorBounds(llbounds) {
  var proj = new OpenLayers.Projection("EPSG:4326");
  var newbounds = llbounds.transform(proj, to_map.getProjectionObject());

  return newbounds;

}

//this function is called is a map has no gcps, and fuzzy best guess
//locations are found. This uses Yahoo's Placemaker service.
function bestGuess(guessObj) {
  jQuery("#to_map_notification").hide();
  if (guessObj["status"] == "ok" && guessObj["count"] > 0) {
    var siblingExtent = guessObj["sibling_extent"];
    zoom = 10;
    if (siblingExtent) {
      sibBounds = new OpenLayers.Bounds.fromString(siblingExtent);
      zoom = to_map.getZoomForExtent(sibBounds.transform(to_map.displayProjection, to_map.projection));
    }
    var places = guessObj["places"];
    var message = "Map zoomed to best guess: " +
            "<a href='#' onclick='centerToMap(" + places[0].lon + "," + places[0].lat + "," + zoom + ");return false;'>" + places[0].name + "</a><br />";
    centerToMap(places[0].lon, places[0].lat, zoom);

    if (places.length > 1) {
      message = message + "Other places:<br />";
      for (var i = 1; i < places.length; i++) {
        var place = places[i];
        message = message + "<a href='#' onclick='centerToMap(" + place.lon + "," + place.lat + "," + zoom + ");return false;'>" + place.name + "</a><br />"
      }
    }
    jQuery("#to_map_notification_inner").html(message);
    jQuery("#to_map_notification").show('slow');
  }

}
function centerToMap(lon, lat, zoom) {
  var newCenter = new OpenLayers.LonLat(lon, lat).transform(to_map.displayProjection, to_map.projection);
  to_map.setCenter(newCenter, zoom);
}

function centerOnMarker(markerID){
	//console.log('centerOnMarker: ' + markerID);

	var imageLon = jQuery('input#x' + markerID).val();
	var imageLat = jQuery('input#y' + markerID).val();

	var mapLon = jQuery('input#lon' + markerID).val();
	var mapLat = jQuery('input#lat' + markerID).val();

	from_map.setCenter(new OpenLayers.LonLat(imageLon,image_height - imageLat), from_map.zoom)
	to_map.setCenter(lonLatToMercator(new OpenLayers.LonLat(mapLon, mapLat)), to_map.zoom)
}

function warp_updateSize() {
  //console.log('warp_updateSize')

  
  var headerSpace = 255

  var minHeight = 370;
  var calculatedHeight = Number(window.innerHeight - headerSpace);

  if (calculatedHeight < minHeight){
    calculatedHeight = minHeight;
  } 

  from_map.div.style.height = calculatedHeight + "px";
  from_map.div.style.width = "100%";
  from_map.updateSize();

  to_map.div.style.height = calculatedHeight + "px";
  to_map.div.style.width = "100%";
  to_map.updateSize();

  // calculate the distance from the top of the browser to the top of the tabs to set the scroll position correctly
  var ele = document.getElementById("wooTabs");
  var offsetFromTop = 0;
  while(ele){
     offsetFromTop += ele.offsetTop;
     ele = ele.offsetParent;
  }

  //window.scrollTo(0, offsetFromTop);

  /* animate the scroll position transition  */
  jQuery('html, body').clearQueue();
  jQuery('html, body').animate({
        scrollTop: offsetFromTop
    }, 500);
 
 setTimeout( removePlaceholderHeight, 500);
}
