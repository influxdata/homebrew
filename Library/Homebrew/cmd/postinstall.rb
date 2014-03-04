require 'formula_installer'

module Homebrew extend self
  def postinstall
    Stats.track_command(:postinstall)

    ARGV.formulae.each {|f| f.post_install }
  end
end
