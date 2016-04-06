var vectors, formats;
var controls;
var clipmap;
var navigate;
var modify;
var polygon;
var deletePoly;
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

  // mds is disabled to prevent scrollwheel
  //var mds = new OpenLayers.Control.MouseDefaults();

  var iw = clip_image_width + 1000; // why the extra width and height?
  var ih = clip_image_height + 500;
  clipmap = new OpenLayers.Map('clipmap', {
    controls: [new OpenLayers.Control.PanZoomBar()],
    maxExtent: new OpenLayers.Bounds(-1000, 0, iw, ih),
    maxResolution: 'auto',
    numZoomLevels: 8
  });

  var image = new OpenLayers.Layer.WMS(title,
          clip_wms_url, {
            layers: 'basic',
            format: 'image/png',
            status: 'unwarped'
          });

  clipmap.addLayer(image);
  if (!clipmap.getCenter()) {
    clipmap.zoomToMaxExtent();
  }
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

  clipmap.div.style.height = Number(window.innerHeight - headerSpace) + "px";
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

