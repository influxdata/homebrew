require "cmd/fetch"

module Homebrew extend self
  def __cache
    Stats.track_command("--cache")

    if ARGV.named.empty?
      puts HOMEBREW_CACHE
    else
      ARGV.formulae.each do |f|
        if fetch_bottle?(f)
          puts f.bottle.cached_download
        else
          puts f.cached_download
        end
      end
    end
  end
end
