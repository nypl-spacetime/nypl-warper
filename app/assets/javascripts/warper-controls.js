/* --------------------
 * GLOBAL MAP CONTROLS
 * -------------------- 
 */

if(typeof maps === 'undefined'){
	var maps = {};
}

var warperGamepad = {};

//
// GAMEPAD API
//
warperGamepad.haveEvents = 'GamepadEvent' in window;
warperGamepad.haveWebkitEvents = 'WebKitGamepadEvent' in window;
warperGamepad.controllers = {};
warperGamepad.gamepadInterval = 0;
warperGamepad.processingButton0 = false;
warperGamepad.processingButton1 = false;


var rAF = window.mozRequestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.requestAnimationFrame;

warperGamepad.connectHandler = function(e) {
	console.log('warperGamepad.connectHandler')
	warperGamepad.addGamepad(e.gamepad);
}
warperGamepad.addGamepad = function(gamepad) {
	console.log(gamepad);
	warperGamepad.controllers[gamepad.index] = gamepad; 
	rAF(warperGamepad.updateStatus);
}

warperGamepad.disconnectHandler = function(e) {
	warperGamepad.removeGamepad(e.gamepad);
}

warperGamepad.removeGamepad = function(gamepad) {
	delete warperGamepad.controllers[gamepad.index];
}

warperGamepad.updateStatus = function(){
	//console.log('updateStatus - warperGamepad.gamepadInterval: ' + warperGamepad.gamepadInterval)
	warperGamepad.gamepadInterval++;
	warperGamepad.scanGamepads();

	if (typeof maps != 'undefined' && typeof currentMaps != 'undefined'){

		for (j in warperGamepad.controllers) {
			var controller = warperGamepad.controllers[j]

			// check if there is input to respond to
			if (controller.axes[0] !== 0 || controller.axes[1] !== 0 || controller.axes[2] !== 0 ){

				if (warperGamepad.gamepadInterval === 1){

					// check if panning is appropiate 
					if (controller.axes[0] !== 0 || controller.axes[1] !== 0){
						var eastWest = controller.axes[0]*5000;
						var northSouth = controller.axes[1]*5000;

						//console.log('pan left/right: ' + controller.axes[0] + ' pan up/down: ' + controller.axes[1] );
						for (var i = 0; i < currentMaps.length; i++) {
							//console.log('panning: ' + currentMaps[i]);
							maps[ currentMaps[i] ].map.pan(eastWest, northSouth);
						};
					}

				} else if (warperGamepad.gamepadInterval === 2){ 

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

				if (controller.buttons[0].pressed && warperGamepad.processingButton0 === false && typeof maps['from_map'] != 'undefined'){
					warperGamepad.processingButton0 = true;
					enableWarpMap('from_map');
				} 

				if (controller.buttons[1].pressed && warperGamepad.processingButton1 === false && typeof maps['to_map'] != 'undefined'){
					warperGamepad.processingButton1 = true;
					enableWarpMap('to_map');
				} 

				if (controller.buttons[0].pressed && controller.buttons[1].pressed && typeof maps['to_map'] != 'undefined'){
					warperGamepad.processingButton0 = true;
					warperGamepad.processingButton1 = true;
					enableWarpMap('both');
				}


			} else {
				warperGamepad.processingButton0 = false;
				warperGamepad.processingButton1 = false;
			}


		}
	}

  if (warperGamepad.gamepadInterval === 3){
    warperGamepad.gamepadInterval = 0;
  }
  rAF(warperGamepad.updateStatus);
}

warperGamepad.scanGamepads = function() {
    //console.log('scangamepads');
    var gamepads = navigator.getGamepads ? navigator.getGamepads() : (navigator.webkitGetGamepads ? navigator.webkitGetGamepads() : []);
    for (var i = 0; i < gamepads.length; i++) {
        if (gamepads[i]) {
              if (!(gamepads[i].index in warperGamepad.controllers)) {
                    warperGamepad.addGamepad(gamepads[i]);
              } else {
                    warperGamepad.controllers[gamepads[i].index] = gamepads[i];
              }
        }
    }
}

// since chrome does not handle page refreshes properly
// lets manually check for gamepads if none were detected at launch
// https://bugs.chromium.org/p/chromium/issues/detail?id=502824&q=gamepadconnected&colspec=ID%20Pri%20M%20Stars%20ReleaseBlock%20Component%20Status%20Owner%20Summary%20OS%20Modified#
warperGamepad.chromeWorkaround = function(){
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
     if(warperGamepad.controllers[0] == undefined){
        warperGamepad.scanGamepads();
     }
  } else { 
     // not Google Chrome 
  }
}



if (warperGamepad.haveEvents) {
    //console.log('warperGamepad.haveEvents', warperGamepad.haveEvents)
    window.addEventListener("gamepadconnected", warperGamepad.connectHandler);
    window.addEventListener("gamepaddisconnected", warperGamepad.disconnectHandler);
    warperGamepad.chromeWorkaround();
} else if (haveWebkitEvents) {
    //console.log('haveWebkitEvents', haveWebkitEvents)
    window.addEventListener("webkitgamepadconnected", warperGamepad.connectHandler);
    window.addEventListener("webkitgamepaddisconnected", warperGamepad.disconnectHandler);
} else {
    setInterval(warperGamepad.scanGamepads, 500);
}




//
// zoom controls 
//

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
    //umap.addControl(keyboardControl);


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