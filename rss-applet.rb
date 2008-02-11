#!/usr/bin/ruby
#
# Copyright 2008, Matt Colyer
#
# This package is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This package is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with this package; if not, write to the Free Software
# Foundation, 51 Franklin Street, Fifth Floor, Boston, MA, 02110-1301 USA.
#

require 'gtk2'
require 'gconf2'
require 'net/http'
require 'feedparser'
require 'feedparser/text-output'
require 'uri'
require 'time'
require 'date'

URL = 'http://sfbay.craigslist.org/sfc/zip/index.rss'
SECONDS_TO_DISPLAY = 30
CACHE_TIMEOUT = (15.0/(60*24))

$gconf_client = GConf::Client.default

class RssApplet < Gtk::Window
  def initialize()
    super(Gtk::Window::TOPLEVEL)
    set_title("RSS Applet")
    set_border_width(5)

    signal_connect("destroy"){
      destroy(self)
    }

    @current_item_index = 0

    update_items
    
    # Setup the headline widget to be displayed
    @headline = Gtk::LinkButton.new(@items.first.link, @items.first.title)
    @headline.signal_connect('clicked') {link_clicked(@headline.uri)}
    add(@headline)

    Gtk.timeout_add(SECONDS_TO_DISPLAY * 1000) do
      show_next_headline()
    end

    show_all
  end

  # Event handler for clicking on a link
  def link_clicked(url)
    browser_command = $gconf_client["/desktop/gnome/url-handlers/http/command"]
    fork {system(browser_command % url)}
  end

  # Switches the headline label to the next headline. If it has already
  # displayed all the items in the list, refresh the RSS for new headlines.
  def show_next_headline()
    @current_item_index += 1

    if @current_item_index == @items.length
      @current_item_index = 0
      update_items
    end
    
    @headline.label = @items[@current_item_index].title
    @headline.uri = @items[@current_item_index].link
  end

  # Gather the new RSS list as long as it has been longer than 15 minutes from
  # the last update.
  def update_items()
    if not @next_update or @next_update < DateTime.now
      s = Net::HTTP::get_response(URI::parse(URL))
      @next_update = DateTime.parse(s['last-modified']) + CACHE_TIMEOUT
      print @next_update
      f = FeedParser::Feed::new(s.body)
      @items = f.items
    end
  end

  # Cleanup function
  def destroy(widget)
    Gtk.main_quit
  end
end

Gtk.init
RssApplet.new
Gtk.main
