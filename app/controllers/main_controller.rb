class MainController < ApplicationController

def index
  # foo
  #render :text => "foo", :layout => true
  
  @racks = YAML.load(File.read(File.expand_path("../../../config/rack_config.yml", __FILE__)))
  puts @racks
  
  #@racks = ["Rack 1", "Rack 2"]
end

end
