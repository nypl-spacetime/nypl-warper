var umap;
var un_bounds;
var unwarped_image;

if(typeof maps === 'undefined'){
	var maps = {};
}

maps['unwarped'] = {};
maps['unwarped'].zoomWheel = new OpenLayers.Control.Navigation( { zoomWheelEnabled: true } );
maps['unwarped'].panZoomBar = new OpenLayers.Control.PanZoomBar();
maps['unwarped'].keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' });

maps['unwarped'].newZoom = null;
maps['unwarped'].oldZoom = null;

maps['unwarped'].resolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18]

maps['unwarped'].active = false;
maps['unwarped'].deactivate = function(){
  //console.log('unwarped deactivate');
  maps['unwarped'].keyboard.deactivate();
  maps['unwarped'].active = false;
}
maps['unwarped'].activate = function(){
  //console.log('unwarped activate');
  maps['unwarped'].keyboard.activate();
  maps['unwarped'].active = true;
  unwarped_updateSize();
  currentMaps = ['unwarped'];
}


function uinit() {
  delete umap;
  delete unwarped_image;
  un_bounds = new OpenLayers.Bounds(0, 0, unwarped_image_width, unwarped_image_height);

  unwarped_init();
  window.addEventListener("resize", unwarped_updateSize);
}

function unwarped_init() {

  if (typeof (umap) == 'undefined') {

    umap = new OpenLayers.Map('unmap',
      {
        controls: [maps['unwarped'].panZoomBar, maps['unwarped'].zoomWheel, maps['unwarped'].keyboard], 
        maxExtent: un_bounds, 
        resolutions: maps['unwarped'].resolutions

      }
    );

    maps['unwarped'].map = umap;

    umap.events.register("addlayer", umap, function(e) {
      //console.log('on addlayer event, adjusting zoom')
    });

    // adjust map size before the layer is added to obtain the correct zoomToMaxExtent
    unwarped_updateSize();


    unwarped_image = new OpenLayers.Layer.WMS(title, wms_url, {format: 'image/png', status: 'unwarped'}, { transitionEffect: 'resize' } );

    /*
    unwarped_image.events.register('loadend', unwarped_image, function(evt){
      //map.zoomToExtent(uses_layer.getDataExtent())
      umap.zoomToMaxExtent();
    })
    */

    umap.addLayer(unwarped_image);

    umap.events.register("zoomend", umap, function(){
        //console.log('zoomend -- umap.zoom: ' + umap.zoom + ' maps['unwarped'].newZoom: ' + maps['unwarped'].newZoom);
        if (umap.zoom < maps['unwarped'].newZoom){
          //console.log('adding .5 to accommediate for the math.floor -- umap.zoom: ' + umap.zoom + ' maps['unwarped'].newZoom: ' + maps['unwarped'].newZoom);
          maps['unwarped'].newZoom = umap.zoom + 0.5;
        } else {
          maps['unwarped'].newZoom = umap.zoom;
        }
    });

  }
  
  //umap.zoomToExtent(un_bounds);
  umap.zoomToMaxExtent();
}

function unwarped_updateSize() {
  //console.log('unwarper_updateSize')

  var minHeight = 500;

  // calculate the distance from the top of the browser to the top of the tabs to determine space available for preview
  var ele = document.getElementById("wooTabs");
  var offsetFromTop = 0;
  while(ele){
     offsetFromTop += ele.offsetTop;
     ele = ele.offsetParent;
  }

  var calculatedHeight = Number(window.innerHeight - offsetFromTop);

  if (calculatedHeight < minHeight){
    calculatedHeight = minHeight;
  } 

  if (typeof umap != 'undefined'){
	  umap.div.style.height =  calculatedHeight + "px";
	  umap.div.style.width = "100%";
	  umap.updateSize();  	
  }



  // since this tab is loaded even when deep linked to another tab lets make certain its really selected
  if (jQuery("div.ui-tabs-panel#Show").css('display') === 'block'){

    // lets be certain the entire page is visible if returning from a tab which had been scrolled down
    var scroll = jQuery(window).scrollTop();


    if (scroll != 100){
      jQuery('html, body').clearQueue();
      jQuery('html, body').animate({
        scrollTop: 100
      }, 500);
    }

  }  

  setTimeout( removePlaceholderHeight, 700);

}

function removePlaceholderHeight(){
  jQuery("div#wooTabs").css({'min-height': ''});
}

