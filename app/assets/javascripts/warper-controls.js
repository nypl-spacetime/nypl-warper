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