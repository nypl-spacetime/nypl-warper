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


    // keyboard shortcuts for switching tools
    var keyboardControl = new OpenLayers.Control();  
    var callbacks = { keydown: function(evt) {
      //console.log("You pressed a key: " + evt.keyCode);
      if (typeof currentMaps != 'undefined'){

        switch(evt.keyCode) {

            case 173: // top row - in firefox
                maps.changeZoom('out');
                break;

            /* numbers at top of keyboard */
            case 49: // 1
                maps.changeZoom(1);
                break;
            case 50: // -
                maps.changeZoom(2);
                break;
            case 51: // -
                maps.changeZoom(3);
                break;
            case 52: // -
                maps.changeZoom(4);
                break;
            case 53: // -
                maps.changeZoom(5);
                break;
            case 54: // -
                maps.changeZoom(6);
                break;
            case 55: // -
                maps.changeZoom(7);
                break;
            case 56: // -
                maps.changeZoom(8);
                break;
            case 57: // -
                maps.changeZoom(9);
                break;


            /* numeric keypad */
            case 96: // 0
                maps.changeZoom(1);
                break;
            case 97: // 1
                maps.changeZoom(1);
                break;
            case 98: // -
                maps.changeZoom(2);
                break;
            case 99: // -
                maps.changeZoom(3);
                break;
            case 100: // -
                maps.changeZoom(4);
                break;
            case 101: // -
                maps.changeZoom(5);
                break;
            case 102: // -
                maps.changeZoom(6);
                break;
            case 103: // -
                maps.changeZoom(7);
                break;
            case 104: // -
                maps.changeZoom(8);
                break;
            case 105: // -
                maps.changeZoom(9);
                break;

            default:
              //console.log('default')
            }
        }
      

      }
    };
          
    var keyboardHandler = new OpenLayers.Handler.Keyboard(keyboardControl, callbacks, {} );

    keyboardHandler.activate();
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



/* --------------------
 * GLOBAL MAP CONTROLS
 * -------------------- 
 */

//
// GAMEPAD API
//
var haveEvents = 'GamepadEvent' in window;
var haveWebkitEvents = 'WebKitGamepadEvent' in window;
var controllers = {};
var gamepadInterval = 0;
var processingButton = false;

var rAF = window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.requestAnimationFrame;

function connecthandler(e) {
  addgamepad(e.gamepad);
}
function addgamepad(gamepad) {
  console.log(gamepad);
  controllers[gamepad.index] = gamepad; 
  
  rAF(updateStatus);
}

function disconnecthandler(e) {
  removegamepad(e.gamepad);
}

function removegamepad(gamepad) {
  delete controllers[gamepad.index];
}

function updateStatus() {
	gamepadInterval++;
	scangamepads();

	if (typeof maps != 'undefined' && typeof currentMaps != 'undefined'){

		for (j in controllers) {
			var controller = controllers[j]

			// check if there is input to respond to
			if (controller.axes[0] !== 0 || controller.axes[1] !== 0 || controller.axes[2] !== 0 ){

				if (gamepadInterval === 1){

					// check if panning is appropiate 
					if (controller.axes[0] !== 0 || controller.axes[1] !== 0){
						var eastWest = controller.axes[0]*5000;
						var northSouth = controller.axes[1]*5000;

						//console.log('pan left/right: ' + controller.axes[0] + ' pan up/down: ' + controller.axes[1] );
						for (var i = 0; i < currentMaps.length; i++) {
							//console.log('panning: ' + currentMaps[i]);
							maps[ currentMaps[i] ].map.pan(eastWest, northSouth);
						};
						//umap.pan(eastWest, northSouth);
					}

				} else if (gamepadInterval === 2){ 

					// reduce the threshold at which zoom occurs to avoid accidental changes when panning
					if (controller.axes[2] > 0.02 || controller.axes[2] < -0.02 ){

						for (var i = 0; i < currentMaps.length; i++) {
							var m = maps[ currentMaps[i] ];

							var proposedZoom = m.newZoom + Number(controller.axes[2] * 2 );
							//console.log(currentMaps[i] + ' proposedZoom: ' + proposedZoom + ' raw: ' + controller.axes[2] );

							// make sure we're in range
							if (m.map.isValidZoomLevel( Math.floor(proposedZoom) ) && proposedZoom > 0) {
								m.newZoom = proposedZoom;

								// first make sure we're within range
								var newFloor = Math.floor(m.newZoom);
								var oldFloor = Math.floor(m.map.zoom);

								// next check that the proposed change is an actual change
								//console.log('newFloor: ' + newFloor + ' oldFloor: ' + oldFloor);
								if (newFloor > oldFloor || newFloor < oldFloor){
									//console.log('---> apply zoom: ' + newFloor );
									m.map.zoomTo(newFloor);
								}
							}


						};

					}

				} 

			}

			// check buttons
			if (controller.buttons[0].pressed || controller.buttons[1].pressed){

				// make sure we haven't already received this button press
				if (processingButton === false){
					processingButton = true;

					if (controller.buttons[0].pressed && typeof maps['from_map'] != 'undefined'){
						toggleWarpMap('from_map');
					}

					if (controller.buttons[1].pressed && typeof maps['to_map'] != 'undefined'){
						toggleWarpMap('to_map');
					}

				}

			} else {

				processingButton = false;
			}


		}
	}

  if (gamepadInterval === 3){
    gamepadInterval = 0;
  }
  rAF(updateStatus);
}

function scangamepads() {
    //console.log('scangamepads');
    var gamepads = navigator.getGamepads ? navigator.getGamepads() : (navigator.webkitGetGamepads ? navigator.webkitGetGamepads() : []);
    for (var i = 0; i < gamepads.length; i++) {
        if (gamepads[i]) {
              if (!(gamepads[i].index in controllers)) {
                    addgamepad(gamepads[i]);
              } else {
                    controllers[gamepads[i].index] = gamepads[i];
              }
        }
    }
}

if (haveEvents) {
    //console.log('haveEvents', haveEvents)
    window.addEventListener("gamepadconnected", connecthandler);
    window.addEventListener("gamepaddisconnected", disconnecthandler);
    setTimeout(chromeWorkaround, 200);
} else if (haveWebkitEvents) {
    //console.log('haveWebkitEvents', haveWebkitEvents)
    window.addEventListener("webkitgamepadconnected", connecthandler);
    window.addEventListener("webkitgamepaddisconnected", disconnecthandler);
} else {
    setInterval(scangamepads, 500);
}

// since chrome does not handle page refreshes properly
// lets manually check for gamepads if none were detected at launch
// https://bugs.chromium.org/p/chromium/issues/detail?id=502824&q=gamepadconnected&colspec=ID%20Pri%20M%20Stars%20ReleaseBlock%20Component%20Status%20Owner%20Summary%20OS%20Modified#
function chromeWorkaround(){
  var isChromium = window.chrome,
    winNav = window.navigator,
    vendorName = winNav.vendor,
    isOpera = winNav.userAgent.indexOf("OPR") > -1,
    isIEedge = winNav.userAgent.indexOf("Edge") > -1,
    isIOSChrome = winNav.userAgent.match("CriOS");

  if(isIOSChrome){
     // is Google Chrome on IOS
  } else if(isChromium !== null && isChromium !== undefined && vendorName === "Google Inc." && isOpera == false && isIEedge == false) {
     // is Google Chrome
     if(controllers[0] == undefined){
        scangamepads();
     }
  } else { 
     // not Google Chrome 
  }
}


//
// zoom controls 
//
maps.changeZoom = function(zoom){
  switch(zoom) {
      	case 'in':
			for (var i = 0; i < currentMaps.length; i++) {
				//console.log('panning: ' + currentMaps[i]);
				maps[ currentMaps[i] ].map.zoomTo(maps[ currentMaps[i] ].map.zoom - 1)
			};
          	break;
      case 'out':
			for (var i = 0; i < currentMaps.length; i++) {
				//console.log('panning: ' + currentMaps[i]);
				maps[ currentMaps[i] ].map.zoomTo(maps[ currentMaps[i] ].map.zoom + 1)
			};
          	break;
      default: 
          // assumming number
			for (var i = 0; i < currentMaps.length; i++) {
				//console.log('panning: ' + currentMaps[i]);
				maps[ currentMaps[i] ].map.zoomTo(maps[ currentMaps[i] ].resolutions.length - Number(zoom * 2) ) ;
			};
          
  }
}