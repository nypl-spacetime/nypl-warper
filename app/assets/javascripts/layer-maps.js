var layerMap;
var mapIndexLayer;
var mapIndexSelCtrl;
var selectedFeature;



if(typeof maps === 'undefined'){
  var maps = {};
}

maps['layer'] = {};
maps['layer'].zoomWheel = new OpenLayers.Control.Navigation( { zoomWheelEnabled: false } );
maps['layer'].panZoomBar = new OpenLayers.Control.PanZoomBar();
maps['layer'].keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' });

maps['layer'].newZoom = null;
maps['layer'].oldZoom = null;

maps['layer'].resolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18] // not applied at the moment

maps['layer'].active = true;

if(typeof currentMaps === 'undefined'){
  var currentMaps = {};
}
currentMaps = ['layer'];



function init(){
  OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3;
  OpenLayers.Util.onImageLoadErrorColor = "transparent";

  var switcher = new OpenLayers.Control.LayerSwitcher(); 
  var options = {
    projection: new OpenLayers.Projection("EPSG:900913"),
    displayProjection: new OpenLayers.Projection("EPSG:4326"),
    units: "m",
    numZoomLevels:22,
    maxResolution: 156543.0339,
    maxExtent: new OpenLayers.Bounds(-20037508, -20037508,
      20037508, 20037508.34),
    controls: [
    new OpenLayers.Control.Attribution(),
    switcher,
    maps['layer'].zoomWheel,
    maps['layer'].panZoomBar,
    maps['layer'].keyboard
    ]
  };

  layerMap = new OpenLayers.Map("map",options);
  maps['layer'].map = layerMap;

  layerMap.events.register("zoomend", layerMap, function(){

    if (layerMap.zoom < maps['layer'].newZoom){
      maps['layer'].newZoom = layerMap.zoom + 0.5;
    } else {
      maps['layer'].newZoom = layerMap.zoom;
    }
  });


  mapnik_lay1 = mapnik.clone();


  nyc_lay1 = ny_2014.clone();
  nyc_lay1.setIsBaseLayer(true);

  layerMap.addLayers([mapnik_lay1,nyc_lay1]);

  wmslayer =  new OpenLayers.Layer.WMS
  ( "Layer"+layer_id,
    warpedwms_url,
    {format: 'image/png', layers: "image" },
    {         TRANSPARENT:'true', reproject: 'true'},
    { gutter: 15, buffer:0},
    { projection:"epsg:4326", units: "m"  }
  );
  wmslayer.setIsBaseLayer(false);
  wmslayer.visibility = true;
  layerMap.addLayer(wmslayer);
  
  bounds_merc = new OpenLayers.Bounds();
  bounds_merc = warped_bounds.transform(layerMap.displayProjection, layerMap.projection);
  
  layerMap.zoomToExtent(bounds_merc);
  layerMap.updateSize();
  
  /*
  layerMap.events.register("zoomend", mapnik_lay1, function () {
    if (this.map.getZoom() > 18 && this.visibility == true) {
      this.map.setBaseLayer(nyc_lay1);
      switcher.maximizeControl();
    }
  });

  layerMap.events.register("zoomend", nyc_lay1, function () {
    if (this.map.getZoom() < 15 && this.visibility == true) {
      this.map.setBaseLayer(mapnik_lay1);
    }
  });
  */
  
  //set up the map index layer to help find individual maps
  var mapIndexLayerStyle = OpenLayers.Util.extend({strokeWidth: 3}, OpenLayers.Feature.Vector.style['default']);
  var mapIndexSelectStyle = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['select']);
  var style_red = {
    fill: true,
    strokeColor: "#FF0000",
    strokeWidth: 3,
    fillOpacity: 0
  };
  var styleMap = new OpenLayers.StyleMap({
      'default': style_red,
      'select': mapIndexSelectStyle
    });
  
  mapIndexLayer = new OpenLayers.Layer.Vector("Map Outlines", {styleMap: styleMap, visibility: false});
  mapIndexSelCtrl = new OpenLayers.Control.SelectFeature(mapIndexLayer, {hover:false, onSelect: onFeatureSelect, onUnselect: onFeatureUnselect});
  layerMap.addControl(mapIndexSelCtrl);
  mapIndexSelCtrl.activate();
  layerMap.addLayer(mapIndexLayer);


  jQuery("#layer-slider").slider({
      value: 100,
      range: "min",
      slide: function(e, ui) {
        wmslayer.setOpacity(ui.value / 100);
        OpenLayers.Util.getElement('opacity').value = ui.value;
      }
    });

  loadMapFeatures();

  jQuery("#view-maps-index-link").append("(<a href='javascript:toggleMapIndexLayer();'>Toggle map outlines on map above</a>)");

  window.addEventListener("resize", layer_updateSize);
  layer_updateSize();
}

function toggleMapIndexLayer(){
  var vis = mapIndexLayer.getVisibility();
  mapIndexLayer.setVisibility(!vis);
}

function loadMapFeatures(){
  var options = {'format': 'json'};
  OpenLayers.loadURL(mapLayersURL,
    options ,
    this,
    loadItems,
    failMessage);
}

function loadItems(resp){
  var g = new OpenLayers.Format.JSON();
  jobj = g.read(resp.responseText);
  lmaps = jobj.items;
  for (var a=0;a<lmaps.length;a++){
    var lmap = lmaps[a];
    if (lmap.bbox == undefined || lmap.bbox == "") continue;
    addMapToMapLayer(lmap);
  }
}

function failMessage(resp){
  alert("Sorry, something went wrong loading the items");
}

function addMapToMapLayer(mapitem){
  var feature = new OpenLayers.Feature.Vector((
      new OpenLayers.Bounds.fromString(mapitem.bbox).transform(layerMap.displayProjection, layerMap.projection)).toGeometry());
  feature.mapTitle = mapitem.title; 
  feature.mapId = mapitem.id;
  mapIndexLayer.addFeatures([feature]);
}

function onPopupClose(evt) {
  mapIndexSelCtrl.unselect(selectedFeature);
}
function onFeatureSelect(feature) {
  selectedFeature = feature;
  popup = new OpenLayers.Popup.FramedCloud("amber_lamps", 
    feature.geometry.getBounds().getCenterLonLat(),
    null,
    "<div class='layermap-popup'> Map "+
      feature.mapId + "<br /> <a href='" + mapBaseURL + "/"+ feature.mapId + "' target='_blank'>"+feature.mapTitle+"</a><br />"+
      "<img src='"+mapThumbBaseURL+feature.mapId+"' height='80'>"+
      "<br /> <a href='"+mapBaseURL+"/"+feature.mapId+"#Rectify_tab' target='_blank'>Edit this map</a>"+
      "</div>",
    null, true, onPopupClose);
  popup.minSize = new OpenLayers.Size(180,150);
  feature.popup = popup;
  layerMap.addPopup(popup);
}

function onFeatureUnselect(feature) {
  layerMap.removePopup(feature.popup);
  feature.popup.destroy();
  feature.popup = null;
}  


function layer_updateSize(){

  var headerSpace = 160
  var minHeight = 500;
  var calculatedHeight = Number(window.innerHeight - headerSpace);

  if (calculatedHeight < minHeight){
    calculatedHeight = minHeight;
  } 

  layerMap.div.style.height = calculatedHeight + "px";
  layerMap.div.style.width = "100%";
  layerMap.updateSize();

  // calculate the distance from the top of the browser to the top of the tabs to set the scroll position correctly
  var ele = document.getElementById("wooTabs");
  var offsetFromTop = 0;
  while(ele){
     offsetFromTop += ele.offsetTop;
     ele = ele.offsetParent;
  }

  //window.scrollTo(0, offsetFromTop);

  //animate the scroll position transition
  jQuery('html, body').clearQueue();
  jQuery('html, body').animate({
        scrollTop: offsetFromTop
    }, 500);


}
