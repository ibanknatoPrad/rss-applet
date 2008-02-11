#!/usr/bin/ruby

require 'gtk2'
require 'net/http'
require 'feedparser'
require 'feedparser/text-output'
require 'uri'
require 'time'
require 'date'

URL = 'http://sfbay.craigslist.org/sfc/zip/index.rss'
SECONDS_TO_DISPLAY = 30
CACHE_TIMEOUT = (15.0/(60*24))

class RssApplet < Gtk::Window
  def initialize()
    super(Gtk::Window::TOPLEVEL)
    set_title("Craigslist Applet")
    set_border_width(5)

    signal_connect("destroy"){
      destroy(self)
    }

    @current_item_index = 0

    update_items
    
    #print @items.first.link
    @headline = Gtk::LinkButton.new(@items.first.link, @items.first.title)
    @headline.signal_connect('clicked') {link_clicked(@headline.uri)}
    add(@headline)

    Gtk.timeout_add(SECONDS_TO_DISPLAY * 1000) do
      show_next_headline()
    end

    show_all
  end

  def link_clicked(url)
    fork {system("sensible-browser %s" % url)}
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

  def destroy(widget)
    Gtk.main_quit
  end
end

Gtk.init
RssApplet.new
Gtk.main
