//OpenLayers.ProxyHost = "/cgi-bin/proxy.cgi?url=";
// reference local blank image
Ext.BLANK_IMAGE_URL = 'mfbase/ext/resources/images/default/s.gif';
var map;
var popup;
var minOpacity = 0.1;
var selectFeat;
var clickedPopup;

function toggleClicked(){
clickedPopup = (clickedPopup != true);
}
function feature_info_hover(feature) {

	selectFeat.select(feature);

	if (popup != null) {
		if (!popup.visible()) {
			map.removePopup(popup);
			popup.destroy();
			popup = null;
		}
	}
	if (popup == null) 
		//TODO Use the feature editing properties from edit.html instead of hardcoding
	{	
		popup = new OpenLayers.Popup.FramedCloud("Info", 
				feature.geometry.getBounds().getCenterLonLat(),
				new OpenLayers.Size(200,100),
				"<div style='font-size:9pt'>" + 
				"<br />Feature Name:<b>"+feature.attributes.FeatName+
				"</b><br /> Feature Type: "+feature.attributes.FeatType+
				"<br /> Build Num: "+feature.attributes.BNum+
				"<br /> <br /> Year1: "+feature.attributes.HistYear1+
				"<br /> Year2: "+feature.attributes.HistYear2+
				"<br /> Source: "+feature.attributes.SourceAu+
				"<br /> Source Date: "+feature.attributes.SourceDa+
				"<br /> Added By: "+feature.attributes.CreatedBy+
				"</div>",
				feature.marker, false);

		popup.setOpacity(0.8);
		//popup.setBackgroundColor("yellow");
		feature.popup = popup;
		map.addPopup(popup);
	} else {
		map.removePopup(popup);
		popup.destroy();
		popup = null;
	}
	//OpenLayers.Event.stop(evt);
}  
function feature_info_hide() {
	selectFeat.unselectAll();
	if (popup != null) {
		map.removePopup(popup);
		popup.destroy();
		popup = null;
	}
	//  OpenLayers.Event.stop(evt);
}

var initialExtent;
Ext.onReady(function() {

		Ext.QuickTips.init();
		var store;
		var options, layer;
		var sourceLayers = new Array();

		// var extent = new OpenLayers.Bounds(-74.163,40.571,-73.7368,40.779);
		//   var extent  = new OpenLayers.Bounds(-8256422,4949565,-8208878,4981592);
		initialExtent  = new OpenLayers.Bounds(-8242519.9312756,4965368.2981726,-8230633.9733794,4972094.7566604);

		options = {  maxExtent: new OpenLayers.Bounds(-180, -90, 180, 90)     };
		var options = {
		projection: new OpenLayers.Projection("EPSG:900913"),
		displayProjection: new OpenLayers.Projection("EPSG:4326"),
		units: "m",
		numZoomLevels:21,
		maxResolution: 156543.0339,
		maxExtent: new OpenLayers.Bounds(-20037508, -20037508, 20037508, 20037508.34)
		};


                var mapnik = new OpenLayers.Layer.TMS(
                "OSM Mapnik",
                "http://tile.openstreetmap.org/",
                {   type: 'png', getURL: osm_getTileURL,
                    displayOutsideMaxExtent: true,
                    attribution: '<a href="http://www.openstreetmap.org/">OpenStreetMap</a>' }
            );

                var nyc = new OpenLayers.Layer.WMS("New York City (zoom in)", 
                "http://dev.maps.nypl.org/mapserv?map=/home/tim/geowarper/warper/tmp/nyc.map&",
                {layers: "NYC",TRANSPARENT:'true', reproject: 'true' },
                {numZoomLevels: 23},
                {isBaseLayer: true});
                
                nyc.setIsBaseLayer(true);
                nyc.setVisibility(false);
                map = new OpenLayers.Map(options);

                map.addLayer(mapnik);
                map.addLayer(nyc);

		//TODO add in:
		// wms, wfs layers for the 3 layers
		// onclick to get feature (cycle through 3 of them?)
		// use title / name?	
		
                var demopoly = new OpenLayers.Layer.WFS(
                "NYPL Areas and Structures", 
                "http://dev.maps.nypl.org/geoserver/wfs",
                {typename: 'topp:NYC_Structures_demo2'},

                {
                    typename: 'NYC_Structures_demo2',
                    featurePrefix: 'topp',
                    projection:  new OpenLayers.Projection("EPSG:4326"),
                    geometryName: 'the_geom',
                    extractAttributes: true
                }
            );

               demopoly.style = OpenLayers.Util.applyDefaults({strokeColor: "#22ee00"}, 
 		    OpenLayers.Feature.Vector.style["default"]);
		
                
                var demoPOI = new OpenLayers.Layer.WFS(
                "NYPL Points of Interest", 
                "http://dev.maps.nypl.org/geoserver/wfs",
                {typename: 'topp:NYC_POI_demo'},

                {
                    typename: 'NYC_POI_demo',
                    featurePrefix: 'topp',
                    projection:  new OpenLayers.Projection("EPSG:4326"),
                    geometryName: 'the_geom',
                    extractAttributes: true
                }
		);

		demoPOI.style = OpenLayers.Util.applyDefaults({strokeColor: "#22ff00"}, 
				OpenLayers.Feature.Vector.style["default"]);


		map.addLayers([demopoly, demoPOI]);

		var  hoverstyle = OpenLayers.Util.extend({}, OpenLayers.Feature.Vector.style['select']);
		OpenLayers.Util.extend(hoverstyle, {pointRadius:  2,hoverPointRadius:2,fillOpacity:0.7,strokeWidth:0, strokeOpacity:0.5});

		selectFeat= new OpenLayers.Control.SelectFeature([demopoly,demoPOI], {
			hover:true,  selectStyle: OpenLayers.Util.applyDefaults({fillColor: "red"}, OpenLayers.Feature.Vector.style["select"]),
			callbacks: {
				'over': feature_info_hover, 
				'out':feature_info_hide
				//, 'click': toggleClicked
			}
		});

		map.addControl(selectFeat);
		selectFeat.activate();


		var setupMap = function(viewport) {
		};


                var mapPanel = new GeoExt.MapPanel({
                    region: 'center',
                    title: "Map",
                    map: map,
                    extent: initialExtent
                });

                var layerList = new GeoExt.tree.LayerContainer({
                    text: "All Layers",
                    layerStore: mapPanel.layers,
                    leaf: false,
		    height: 100,
                    expanded: true
                });


             var root = new Ext.tree.TreeNode({
		text: "All Layers",
		expanded: true
		});
             root.appendChild(new GeoExt.tree.BaseLayerContainer({
		text: "Base Layers",
                map: map,
		expanded: true
             }));

             var overlayContainer = new GeoExt.tree.OverlayLayerContainer({
		text: "Overlays",
		map: map,
		expanded: true
             });

	      root.appendChild(overlayContainer);


                var addLayerButton = new Ext.Button({
                    text: "Add Layer",
                    handler: function(pressed){
                        //OpenLayers.Console.log("add layer button pressed");
                        layerWindow.show();
                    }
                });

                var layerToolBar = new Ext.Toolbar({items: [addLayerButton]});

                var layerTree = new Ext.tree.TreePanel({
                     title: "Map Layers",
                    root: root,
		    enableDD: true,
		    collapsible: true,
		    height: 200,
		    tbar: layerToolBar,
		    expanded: true
                });
		layerTree.on('contextmenu', menuShow, this);

		var subMenu = new Ext.menu.Menu({id:'exportMenu'});
		subMenu.add(
	       new Ext.menu.Item({id: 'shape-zip', text: 'SHP (zipped)', handler: taskExport}),
		new Ext.menu.Item({id: 'GML2', text: 'GML v2', handler: taskExport}),
		new Ext.menu.Item({id: 'csv', text: 'CSV', handler: taskExport}),
		new Ext.menu.Item({id: 'georss',text: 'GeoRSS', handler: taskExport, disabled: true}),
		new Ext.menu.Item({id: 'pdf', text: 'PDF', handler: taskExport, disabled:true}),
		new Ext.menu.Item({id: 'svg',text: 'SVG', handler: taskExport, disabled:true})
	     		);


		var menuC = new Ext.menu.Menu('mainContext');
		menuC.add(
		  new Ext.menu.Item({text: 'Zoom to Layer', handler:  taskZoom}),
		  new Ext.menu.Separator(),
		  {
			text: 'Export',
			menu: subMenu
			}
		);
		function taskZoom(node) {
			var selectedLayer = map.getLayersByName(node.parentMenu.activeLayer)[0];
			//console.log(selectedLayer);
			var layerExtent = selectedLayer.getDataExtent();
			if (layerExtent){
				map.zoomToExtent(layerExtent);
			}else {
				map.zoomToExtent(initialExtent);
			}
		}

	      	function taskExport(node){
		var selectedLayer = map.getLayersByName(node.parentMenu.parentMenu.activeLayer)[0];
		var url ="";
//http://dev.maps.nypl.org:8080/geoserver/wms?bbox=-74.81458064799999,39.844969352,-72.859419352,41.800130648&styles=&Format=application/rss%2Bxml&request=GetMap&version=1.1.1&layers=topp:NYC_Structures_demo2&width=600&height=550&srs=EPSG:4326
		 if (node.id == "kml") {
			url = "/geoserver/wms/kml?layers=topp:"+selectedLayer.typename;
		} else if (node.id == "georss"){
			//Format=application/rss+xml";
		} else if (node.id == "svg"){
		// "&Format=image/svg+xml";

		}else if (node.id == "pdf"){
		//application/pdf";
		}else{
		 url = selectedLayer.getFullRequestString() + "&OutputFormat="+node.id;

		}
	//	console.log(url);
		var newWin  = window.open(url, '_blank')
		newWin.focus();	
		}
		function menuShow(node){
		  menuC.activeLayer = node.text;
		  if (node.layer && node.layer.CLASS_NAME == "OpenLayers.Layer.WFS"){
		  menuC.show(node.ui.getAnchor());
	      		}
	      }
                var vp =  new Ext.Viewport({
                    layout: 'border',
                    listeners: {'afterlayout': {'fn': setupMap}},
                    items: [
                        new Ext.BoxComponent({
                            region: 'north',
                            el: 'north',
                            height: 74
                        }), {
                            region: 'east',
                            id: 'east-panel',
                            width: 400,
			    					 autoScroll: true,
                            items: [
                                layerTree,
                                {
				    title: 'Help',
                                    id: 'help',
                                    contentEl: 'helptext',
                                    collapsible: true
                                }]
                        }, 
                        mapPanel                       
                    ]
                });



                wmscapurl = "http://dev.maps.nypl.org/warper-dev/layers/wms2?SERVICE=WMS&REQUEST=GetCapabilities";
                // create a new WMS capabilities store
                store = new GeoExt.data.WMSCapabilitiesStore({
                    url: wmscapurl
                });
                // load the store with records derived from the doc at the above url
                store.load();

                // create a grid to display records from the store
                var grid = new Ext.grid.GridPanel({
                    // title: "WMS Capabilities",
                    store: store,
                    columns: [
                        //{header: "Name", dataIndex: "name", sortable: true},            
                        {header: "Layer", dataIndex: "title", id: "title", sortable: true},
                        {header: "Description", dataIndex: "abstract", id: "abstract", sortable: true}
                    ],
                    autoExpandColumn: "title",
                    sm: new Ext.grid.RowSelectionModel({singleSelect:true}),
                    height: 300,
                    width: 650,
                    listeners: {
                        rowdblclick: clickLayer
                    }
                });
    
                var layerWindow = new Ext.Window({
                    title: "Layer List",
                    width: 600,
                    height: 300,
                    minWidth: 300,
                    minHeight: 200,
                    layout: 'fit',
                    modal: true,
                    plain: false,
                    bodyStyle: 'padding:5px;',
                    items: [grid],
                    closeAction:'hide',
                    buttons: [{
                            text: 'Close',
                            handler: function(){
                                layerWindow.hide();
                            }
                        }]
                });
                //layerWindow.show();

                var addLayer = new Ext.Button({
                    text: "Add Layer To Map",
                    handler: function(pressed){
                       // OpenLayers.Console.log("add layer button pressed");
                    }
                });

                var layerTb = new Ext.Toolbar({items: [addLayer]});

    

                function clickLayer(grid, index) {
                    var record = grid.getStore().getAt(index);
                    var layer = record.get("layer").clone();
                    layer.setIsBaseLayer(false);
                    //layer.setOpacity(0.8);
                   // OpenLayers.Console.log(layer);
                    //layer.DEFAULT_PARAMS.format =  "image/png";
                    layer.params.FORMAT =  "image/png";
                    map.addLayer(layer);
                    sourceLayers.push(layer);
                   // OpenLayers.Console.log(sourceLayers);
		for (var a=0;a<sourceLayers.length;a++){
		//OpenLayers.Console.log(sourceLayers[a]);
		if (sourceLayers[a].getVisibility()){
		  //OpenLayers.Console.log("this layer is visible");						
		}						
		}							
								                    
                     //TODO when double clicked, show a preview?
        
                    //         var mapWin = new Ext.Window({
                    //             title: "Preview: " + record.get("title"),
                    //             width: 512,
                    //             height: 256,
                    //             layout: "fit",
                    // 	    modal: true,
                    // 	    tbar: layerTb,
                    //             items: [{
                    //                 xtype: "gx_mappanel",
                    //                 layers: [layer],
                    //                 extent: record.get("llbbox")
                    //             }]
                    //         });
                    //         mapWin.show();

                }


            });
            function osm_getTileURL(bounds) {
                var res = this.map.getResolution();
                var x = Math.round((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
                var y = Math.round((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
                var z = this.map.getZoom();
                var limit = Math.pow(2, z);

                if (y < 0 || y >= limit) {
                    return OpenLayers.Util.getImagesLocation() + "404.png";
                } else {
                    x = ((x % limit) + limit) % limit;
                    return this.url + z + "/" + x + "/" + y + "." + this.type;
                }
            }
