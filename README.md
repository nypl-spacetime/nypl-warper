# NYPL Map Warper

This software has been developed by Topomancy LLC with the support and
collaboration of the New York Public Library.

You can see this code in action at http://maps.nypl.org/.

---

Consult the wiki for for more documentation including a report detailing the changes in this version compared with the previous version. https://github.com/NYPL/nypl-warper/wiki

--- 

The NYPL Map Warper is an open source map geo-rectification, warping and georeferencing application.
It enables a user to browse and explore the NYPL's historical map collection, and by placing control points on a reference map and the image, to warp it, to stretch it to fit.

![Map Warper screenshot of main interface](/app/assets/images/Screenshot_MapWarper.png?raw=true "Map Warper screenshot of main interface")

The application can be seen in use at http://maps.nypl.org

The application is a web based crowdsourced geospatial project that enables people and organisations to collaboratively publish images of maps online and digitize and extract vector information from them. 

Users rectify, warp or stretch images of historical maps with a reference basemap, assigning locations on image and map that line up with each other. Often these historical maps were in big paper books, and so for the first time they can be stitched together and shown as a whole, in digital format.

Users can crop around the maps, and join them together into layers.

By georeferencing the images, they can be warped or georectified to match the locations in space, and used in GIS software and other services. One such use of these warped maps is an application that that helps people digitize, that is, trace over the maps to extract information from them. For example, buildings in 18th Century Manhattan, details changing land use, building type etc. This application is called the Digitizer.

The application runs as a Ruby on Rails application using a number of open source geospatial libraries and technologies, including PostGIS, Mapserver, Geoserver, and GDAL tools.

The resulting maps can be exported as a PNG, GeoTIFF, WMS, Tiles, and KML for use in many different applications.


## Features

* Find and search maps by geography
* Adding control points to maps side by side
* Crop maps
* User commenting on maps
* Align maps from similar
* Login via Github / Twitter / etc
* OR signup with email and password
* Export as GeoTiff, PNG, WMS, Tile, KML etc
* Preview in Google Earth and Google Maps
* Map Favourites
* Social media sharing
* Bibliographic metatadata creation and export support
* Multiple georectfication options
* Control point from files import
* API
* Admin tools include
  * User statistics
  * Activity monitoring
  * User administration, disabling
  * Roles management (editor, developer, admin etc)
  * Batch Imports
  * User Flags
  * User Statistics
  * Revisions and Rollbacks
 
  

## Note on code and branches

Unmaintained branches exist for older systems and setups

* Rails 2.3 and Ruby 1.8.4 - See the rails2 branch

## Ruby & Rails

* Rails 4.2
* Ruby 1.9+

## Database

* Postgresql 9.1 (or 9.1, 8.4)
* Postgis 2 (may work with 1.5)

## Installation Dependencies

Check out the Vagrant section lower down in the readme if you want to get started quickly.

on Ubuntu 14.04 LTS

```apt-get install -y ruby ruby-dev postgresql-9.3-postgis-2.1 postgresql-server-dev-all postgresql-contrib build-essential git-core libxml2-dev libxslt-dev imagemagick libmapserver1 gdal-bin libgdal-dev ruby-mapscript nodejs```

Due to a bug with the gdal gem, you _may_ need to disable a few flags from your ruby rbconfig.rb see https://github.com/zhm/gdal-ruby/issues/4 for more information

Then install the gem files using bundler

```bundle install```


## Configuration

Create and configure the following files

* `config/secrets.yml`
* `config/database.yml`
* `config/application.yml`

In addition have a look in `config/initializers/application_config.rb `for some other paths and variables, and `config/initializers/devise.rb ` for devise and omniauth and also `config/environments/development.rb` if you rather not use the `/warper` relative path.

## Database creation

Create a postgis database

` psql mapwarper_dev -c "create extension postgis;" `

## Database initialization

Creating a new user

    user = User.new
    user.login = "super"
    user.email = "super@superxyz123.com"
    user.password = "your_password"
    user.password_confirmation = "your_password"
    user.confirmed_at = Time.now
    user.save

    role = Role.find_by_name('super user')

    permission  = Permission.new
    permission.role = role
    permission.user = user
    permission.save

    role = Role.find_by_name('administrator')
    permission = Permission.new
    permission.role = role
    permission.user = user
    permission.save


## Development 

Via Vagrant - There is a [`Vagrantfile`](/Vagrantfile) you can use which uses the [`/lib/vagrant/provision.sh`](/lib/vagrant/provision.sh) provision script. **Note:** the default `Vagrantfile` is configured to take 8GB RAM. To use this file type:

    vagrant up

to get and install the virtual machine - this will also install the libraries and depencies and ruby gems for mapwarper into the virtual machine. See [`/lib/vagrant/provision.sh`](/lib/vagrant/provision.sh) for more details about this process.

After that runs, type `vagrant ssh` to login and then you can:

    cd /srv/mapwarper
    rails c

Create a user in the console, as shown above and then `exit`. Then start the server in a relative url root use `thin`:

    RAILS_ENV=development bundle exec thin --prefix=/warper start

and then browse to `http://localhost:3000/warper/`

In non-Vagrant circumstances you may want to run it just using `rails s`.

## Import a test map

This codebase only supports [maps from NYPL](http://maps.nypl.org/) via the [Digital Collections API](http://api.repo.nypl.org/) (use that link to get an account and token). Fortunately, many of our maps are Public Domain so you can test the warper locally (non PD maps are not downloadable in high-res from the API). The warper imports maps (subject to throttling limits) based on the `UUID` visible in the [item page](http://digitalcollections.nypl.org/items/98b7f36a-3d7a-6c65-e040-e00a18064b00) (`98b7f36a-3d7a-6c65-e040-e00a18064b00` in this case):

1. add the generated API token to `/config/nypl_repo.yml`
2. start the server and log in with a super user
3. go to `Admin / Imports`
4. Click `Add New Import`
5. Select `Import Type`: `Map` and type in the `UUID`: `a66456f6-3860-95d5-e040-e00a18065ecc` and click `Create`
6. Click `Start Import`

This will take a few minutes to pull the map. You now have a map you can work with and test functionality!


## Deployment instructions

The system can use capistrano for deployment

## API

See [`README_API.md`](/README_API.md) for API details


