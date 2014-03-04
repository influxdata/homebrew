module Homebrew extend self
  def unlink
    Stats.track_command(:unlink)

    raise KegUnspecifiedError if ARGV.named.empty?

    ARGV.kegs.each do |keg|
      keg.lock do
        print "Unlinking #{keg}... "
        puts if ARGV.verbose?
        puts "#{keg.unlink} symlinks removed"
      end
    end
  end
end
