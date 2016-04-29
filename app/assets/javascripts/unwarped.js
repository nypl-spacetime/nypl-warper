var un_bounds;
function uinit() {
  delete umap;
  delete unwarped_image;
  un_bounds = new OpenLayers.Bounds(0, 0, unwarped_image_width, unwarped_image_height);

  unwarped_init();
  window.addEventListener("resize", unwarped_updateSize);
}

function unwarped_init() {

  /*
  // mds is disabled in the map setup since it invokes the zoomWheel control and we want that disabled
  var mds = new OpenLayers.Control.MouseDefaults();
  mds.defaultDblClick = function() {
    return true;
  };
  */

  var zoomWheel = new OpenLayers.Control.Navigation( { zoomWheelEnabled: false } );
  var panZoomBar = new OpenLayers.Control.PanZoomBar();


  if (typeof (umap) == 'undefined') {

    umap = new OpenLayers.Map('unmap',
      {
        controls: [panZoomBar, zoomWheel], 
        maxExtent: un_bounds, 
        maxResolution: 10.94, 
        numZoomLevels: 8
      }
    );

    umap.events.register("addlayer", umap, function(e) {
      //console.log('on add layer')
      umap.zoomToMaxExtent();
    });

    var unwarped_image = new OpenLayers.Layer.WMS(title, wms_url, {format: 'image/png', status: 'unwarped'});
    umap.addLayer(unwarped_image);
  }

  if (!umap.getCenter()) {
    console.log('zoomToExtent of un_bounds ---- this never seems to run')
    umap.zoomToExtent(un_bounds);
  }
  
  //umap.zoomToExtent(un_bounds);
  umap.zoomToMaxExtent();

  unwarped_updateSize();
}

function unwarped_updateSize() {
  //console.log('unwarper_updateSize')

  // calculate the distance from the top of the browser to the top of the tabs to determine space available for preview
  var ele = document.getElementById("wooTabs");
  var offsetFromTop = 0;
  while(ele){
     offsetFromTop += ele.offsetTop;
     ele = ele.offsetParent;
  }

  umap.div.style.height = Number(window.innerHeight - offsetFromTop - 90) + "px";
  umap.div.style.width = "100%";

  umap.updateSize();


  // since this tab is loaded even when deep linked to another tab lets make certain its really selected
  if (jQuery("div.ui-tabs-panel#Show").css('display') === 'block'){

    // lets be certain the entire page is visible if returning from a tab which had been scrolled down
    var scroll = jQuery(window).scrollTop();


    if (scroll != 0){
      jQuery('html, body').clearQueue();
      jQuery('html, body').animate({
        scrollTop: 0
      }, 500);
    }

  }  

  setTimeout( removePlaceholderHeight, 700);

}

function removePlaceholderHeight(){
  jQuery("div#wooTabs").css({'min-height': ''});
}

