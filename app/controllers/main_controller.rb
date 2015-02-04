class MainController < ApplicationController

def index

  if params['mode']
    @mode = params['mode']
  else
    @mode = 'overview'
  end

  rack_config = YAML.load(File.read(File.expand_path("../../../config/rack_config.yml", __FILE__)))

  @racks = []
  @general = nil

  rack_config.each do |entry|
    if entry[0].include?("rack")
      @racks << entry
    end
    if entry[0] == "general"
      @general = entry
    end
  end
  
end

end
