var vectors, formats;
var controls;
var clipmap;
var navigate;
var modify;
var polygon;
var deletePoly;

if(typeof maps === 'undefined'){
  var maps = {};
}

maps['clip'] = {};

maps['clip'].zoomWheel = new OpenLayers.Control.Navigation( { zoomWheelEnabled: true } );
maps['clip'].panZoomBar = new OpenLayers.Control.PanZoomBar();
maps['clip'].keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' });

maps['clip'].newZoom = null;
maps['clip'].oldZoom = null;

maps['clip'].resolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18]

maps['clip'].active = false;
maps['clip'].deactivate = function(){
  //console.log('clip deactivate');
  maps['clip'].keyboard.deactivate();
  maps['clip'].active = false;
}
maps['clip'].activate = function(){
  //console.log('clip activate');
  maps['clip'].keyboard.activate();
  maps['clip'].active = true;
  currentMaps = ['clip'];
  clip_updateSize();
}


function updateFormats() {

  formats = {
    'out': {
      //wkt: new OpenLayers.Format.WKT(out_options),
      wkt: new OpenLayers.Format.WKT(),
      geojson: new OpenLayers.Format.GeoJSON(),
      georss: new OpenLayers.Format.GeoRSS(),
      gml: new OpenLayers.Format.GML(),
      kml: new OpenLayers.Format.KML()
    }
  };
}

function clipinit() {

  var iw = clip_image_width + 1000; // why the extra width and height?
  var ih = clip_image_height + 500;
  clipmap = new OpenLayers.Map('clipmap', {
    controls: [maps['clip'].panZoomBar, maps['clip'].zoomWheel],
    maxExtent: new OpenLayers.Bounds(-1000, 0, iw, ih),
    resolutions: maps['clip'].resolutions
  });

  maps['clip'].map = clipmap;

  var image = new OpenLayers.Layer.WMS(title,
          clip_wms_url, {
            layers: 'basic',
            format: 'image/png',
            status: 'unwarped'
          }, { transitionEffect: 'resize' });

  clipmap.addLayer(image);
  if (!clipmap.getCenter()) {
    clipmap.zoomToMaxExtent();
  }

  clipmap.events.register("zoomend", clipmap, function(){

      if (clipmap.zoom < maps['clip'].newZoom){
        maps['clip'].newZoom = clipmap.zoom + 0.5;
      } else {
        maps['clip'].newZoom = clipmap.zoom;
      }
  });



  //if theres a file load it
  //else make a plain one

  if (gml_file_exists) {

    vectors = new OpenLayers.Layer.GML("GML", gml_url);
  } else {
    //console.log ("else");
    vectors = new OpenLayers.Layer.Vector("Vector Layer");
  }
  clipmap.addLayer(vectors);

  updateFormats();

  vectors.styleMap.styles.temporary.defaultStyle.strokeWidth = 3;

  var modifyOptions = {
    onModificationStart: function(feature) {
      //  OpenLayers.Console.log("start modifying", feature.id);
    },
    onModification: function(feature) {
      // OpenLayers.Console.log("modified", feature.id);
    },
    onModificationEnd: function(feature) {
      //  OpenLayers.Console.log("end modifying", feature.id);
    },
    onDelete: function(feature) {
      //  OpenLayers.Console.log("delete", feature.id);
    },
    title: "Modify existing polygon",
    displayClass: "olControlModifyFeature"
  };

  var scratchGeom;
  modify = new OpenLayers.Control.ModifyFeature(vectors, modifyOptions);
  modify.events.register("activate", this, function() {
    scratchGeom = null;
  });
  navigate = new OpenLayers.Control.Navigation({
    title: "Move around Map",
    zoomWheelEnabled: false
  });
  navigate.events.register("activate", this, function() {
    //check to see if theres something in the temp buffer
    if (scratchGeom) {
      polygon.drawFeature(scratchGeom);
    }
  });
  polygon = new OpenLayers.Control.DrawFeature(vectors, OpenLayers.Handler.Polygon,
          {
            callbacks: {
              "cancel": function(polyGeom) {
                scratchGeom = polyGeom.clone();
              }
            }
          },
  {
    title: "Draw new polygon to mask",
    displayClass: 'olControlDrawFeature'
  });


  polygon.featureAdded = function(feature) {
    scratchGeom = null;
    polygon.deactivate();
    modify.activate();
  };

  deletePoly = new OpenLayers.Control.SelectFeature(vectors,
          {
            onSelect: deletePolygon,
            title: "Delete a polygon",
            displayClass: 'olControlDeleteFeature'
          });

  var controlpanel = new OpenLayers.Control.Panel(
          {
            displayClass: 'olControlEditingToolbar2'
          }
  );

  controlpanel.addControls([deletePoly, modify, polygon, navigate]);
  clipmap.addControl(controlpanel);
  navigate.activate();

  window.addEventListener("resize", clip_updateSize);
  clip_updateSize();
  clipmap.zoomToMaxExtent();

}

function deletePolygon(feature) {
  var c = confirm("Really delete this?");
  if (c === true) {
    vectors.removeFeatures([feature]);
  }
  deletePoly.unselectAll();
  deletePoly.deactivate();
  navigate.activate();
}

function destroyMask() {
  vectors.destroyFeatures();
}
function deselect() {
  modify.deactivate();
  polygon.deactivate();
}
//vectors.features[0].geometry.components[0].components[0].x
function serialize_features() {
  // var type = document.getElementById("formatType").value;
  var type = "gml";
  var str = formats['out']['gml'].write(vectors.features);

  document.getElementById('output').value = str;
}

function updateOtherMaps() {
  if (typeof to_map != 'undefined' && typeof warped_layer != 'undefined') {
    warped_layer.mergeNewParams({
      'random': Math.random()
    });
    warped_layer.redraw(true);
  }
  if (typeof warpedmap != 'undefined' && typeof warped_wmslayer != 'undefined') {
    warped_wmslayer.mergeNewParams({
      'random': Math.random()
    });
    warped_wmslayer.redraw(true);
  }
}

function clip_updateSize() {
  //console.log('clip_updateSize')

  var headerSpace = 220
  var minHeight = 500;
  var calculatedHeight = Number(window.innerHeight - headerSpace);
  if (calculatedHeight < minHeight){
    calculatedHeight = minHeight;
  }

  clipmap.div.style.height = calculatedHeight + "px";
  clipmap.div.style.width = "100%";
  clipmap.updateSize();

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

  // clear preset height if one was set
  setTimeout( removePlaceholderHeight, 500);

}

