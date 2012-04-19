 //Layer definitions for OpenLayers

//function used with osm mapnik tiles
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
//use with tiles at home tiles
function get_tilesathome_osm_url (bounds) {
    var res = this.map.getResolution();
    var x = Math.round ((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
    var y = Math.round ((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
    var z = this.map.getZoom();
    var limit = Math.pow(2, z);

    if (y < 0 || y >= limit)
    {
        return null;
    }
    else
    {
        x = ((x % limit) + limit) % limit;
        var path = z + "/" + x + "/" + y + "." + this.type;
        var url = this.url;
        url="http://tah.openstreetmap.org/Tiles/tile/"
        if (url instanceof Array) {
            url = this.selectUrl(path, url);
        }
        return url + path;
    }
}

var osma = new OpenLayers.Layer.TMS(
    "Osmarender",
    ["http://a.tah.openstreetmap.org/Tiles/tile/", "http://b.tah.openstreetmap.org/Tiles/tile/", "http://c.tah.openstreetmap.org/Tiles/tile/"],
    {
        type:'png',
        getURL: get_tilesathome_osm_url,
        displayOutsideMaxExtent: true
    }, {
        'buffer':1
    } );

var mapnik = new OpenLayers.Layer.TMS("Open Street Map", "http://tile.openstreetmap.org/", {
    type: 'png',
    getURL: osm_getTileURL,
    displayOutsideMaxExtent: true,
    transitionEffect: 'resize',
    attribution: '<a href="http://www.openstreetmap.org/">OpenStreetMap</a>'
});


var jpl_wms = new OpenLayers.Layer.WMS("NASA Landsat 7", "http://t1.hypercube.telascience.org/cgi-bin/landsat7", {
    layers: "landsat7"
});

var oamlayer = new OpenLayers.Layer.WMS( "OpenAerialMap",
   "http://openaerialmap.org/wms/",
   {layers: "world"}, { gutter: 15, buffer:0});

var ortho = new OpenLayers.Layer.WMS( "USGS Aerial Photos (2006)",
    ["http://tile1.maps.nypl.org/tilecache",
     "http://tile2.maps.nypl.org/tilecache",
     "http://tile3.maps.nypl.org/tilecache",
     "http://tile4.maps.nypl.org/tilecache" ],
    {layers: 'ortho', sphericalMercator: true, numZoomLevels: 23} );

//http://dev.maps.nypl.org/mapserv?map=/var/lib/maps/src/nyc_data/nyc.map&
//var nyc = new OpenLayers.Layer.WMS("New York City (zoom in)", "http://maps.nypl.org/mapserv?map=/home/tim/geowarper/warper/tmp/nyc.map&",
//    {layers: "NYC",TRANSPARENT:'true', reproject: 'true' },
//    {numZoomLevels: 23});


var dg_crisis = new OpenLayers.Layer.TMS("Digitial Globe Crisis Event Service",  "http://maps.nypl.org/tilecache/1/dg_crisis/", {
    type: 'jpg',
    getURL: osm_getTileURL,
    displayOutsideMaxExtent: true,
    transitionEffect: 'resize'
});

var geoeye = new OpenLayers.Layer.TMS("GeoEye Mosaic",  "http://maps.nypl.org/tilecache/1/geoeye/", {
    type: 'jpg',
    getURL: osm_getTileURL,
    displayOutsideMaxExtent: true,
    transitionEffect: 'resize'
});

   var nyc = new OpenLayers.Layer.TMS("New York City (zoom in)", 
     "http://tile1.maps.nypl.org/nyc_tiles/",
     { type: 'png',
       getURL: osm_getTileURL,
       transitionEffect: 'resize',
       displayOutsideMaxExtent: true,
       wrapDateLine: true,
       numZoomLevels: 20
     });

 // var dg_crisis2 = new OpenLayers.Layer.XYZ(
//   "DigitalGlobe Crisis Event Service",
 //   "http://maps.nypl.org/tilecache/1/dg_crisis/${z}/${x}/${y}.jpg"
 // );
 // var geoeye = new OpenLayers.Layer.XYZ(
 //   "GeoEye mosaic",
 //   "http://maps.nypl.org/tilecache/1/geoeye/${z}/${x}/${y}.jpg"
 // );
