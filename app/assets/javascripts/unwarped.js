var un_bounds;
var unwarped_image;

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



  var zoomWheel = new OpenLayers.Control.Navigation( { zoomWheelEnabled: true } );
  var panZoomBar = new OpenLayers.Control.PanZoomBar();
  var keyboard = new OpenLayers.Control.KeyboardDefaults({ observeElement: 'map' })

  if (typeof (umap) == 'undefined') {

    var mapResolutions = [0.12, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5, 6, 7, 8.5, 10, 14, 18]

    umap = new OpenLayers.Map('unmap',
      {
        controls: [panZoomBar, zoomWheel, keyboard], 
        maxExtent: un_bounds, 
        resolutions: mapResolutions

      }
    );

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

    // keyboard shortcuts for switching tools
    var keyboardControl = new OpenLayers.Control();  
    var control = new OpenLayers.Control();
    var callbacks = { keydown: function(evt) {
      //console.log("You pressed a key: " + evt.keyCode);
      
      switch(evt.keyCode) {
        /* keyboard defaults control picked up the zoom in/out functionality
          case 107: // numeric keypad +
              changeZoom('out');
              break;
          case 109: // numeric keypad -
              changeZoom('in');
              break;

          case 187: // top row +
              changeZoom('out');
              break;
          case 189: // top row -
              changeZoom('in');
              break;
        */

          case 173: // top row - (?)
              changeZoom('out');
              break;

          /* numbers at top of keyboard */
          case 49: // 1
              changeZoom(1);
              break;
          case 50: // -
              changeZoom(2);
              break;
          case 51: // -
              changeZoom(3);
              break;
          case 52: // -
              changeZoom(4);
              break;
          case 53: // -
              changeZoom(5);
              break;
          case 54: // -
              changeZoom(6);
              break;
          case 55: // -
              changeZoom(7);
              break;
          case 56: // -
              changeZoom(8);
              break;
          case 57: // -
              changeZoom(9);
              break;


          /* numeric keypad */
          case 96: // 0
              changeZoom(1);
              break;
          case 97: // 1
              changeZoom(1);
              break;
          case 98: // -
              changeZoom(2);
              break;
          case 99: // -
              changeZoom(3);
              break;
          case 100: // -
              changeZoom(4);
              break;
          case 101: // -
              changeZoom(5);
              break;
          case 102: // -
              changeZoom(6);
              break;
          case 103: // -
              changeZoom(7);
              break;
          case 104: // -
              changeZoom(8);
              break;
          case 105: // -
              changeZoom(9);
              break;

          default:
            //console.log('default')
          }
      }
    };
          
    var options = {};
    var handler = new OpenLayers.Handler.Keyboard(control, callbacks, options);

    function changeZoom(newZoom){

      switch(newZoom) {
          case 'in':
              umap.zoomTo(umap.zoom - 1)
              break;
          case 'out':
              umap.zoomTo(umap.zoom + 1)
              break;
          default: 
              // assumming number
              umap.zoomTo(mapResolutions.length - Number(newZoom * 2) ) ;
      }
    }

    function moveMap(newDirection){
      console.log('moveMap: ' + newDirection);

    }

    handler.activate();
    umap.addControl(keyboardControl);

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

  umap.div.style.height =  calculatedHeight + "px";
  umap.div.style.width = "100%";

  umap.updateSize();


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

