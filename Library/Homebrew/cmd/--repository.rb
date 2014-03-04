module Homebrew extend self
  def __repository
    Stats.track_command("--repository")

    puts HOMEBREW_REPOSITORY
  end
end
