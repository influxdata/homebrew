# So the data that we’d probably want would be:
# * each brew command invocation and the arguments that are passed to it (with flags split out but accessible somewhere so we can see how often they are each used)
# * each formula installation and the options it is built with and if it used a bottle
# * the `brew —config` output on each brew command invocation and/or installation
# * what taps are currently installed
# * any HOMEBREW_* environment variables that are set

class Stats
  HOST = "localhost"
  PORT = 8086
  DATABASE = "brewstats"
  USERNAME = "homebrew"
  PASSWORD = "br3w"

  class << self
    def report(series_name, data)
      data = Array(data)
      columns = data.reduce(:merge).keys.sort {|a,b| a.to_s <=> b.to_s}
      payload = {:name => name, :points => [], :columns => columns}

      data.map do |point|
        payload[:points] << columns.inject([]) do |array, column|
          array << point
        end
      end
    end

    def track_command(command)
      data = {
        "name" => command.to_s,
        "arguments" => ARGV.join(" "),
        "homebrew_sha1" => homebrew_sha1,
        "homebrew_prefix" => HOMEBREW_PREFIX.to_s,
        "homebrew_cellar" => HOMEBREW_CELLAR.to_s,
        "osx_version" => MACOS_FULL_VERSION,
        "llvm" => MacOS.llvm_build_version,
        "gcc_42" => MacOS.gcc_42_build_version,
        "gcc_40" => MacOS.gcc_40_build_version,
        "clang" => MacOS.clang_version,
        "clang_build" => MacOS.clang_build_version,
      }

      curl jsonify("commands", data)
    end

    def track_formula_installation(formula_installer)
      data = {
        "name" => formula_installer.f.name.to_s,
        "version" => formula_installer.f.installed_version.to_s,
        "arguments" => ARGV.join(" "),
      }

      curl jsonify("installations", data)
    end

    def homebrew_environment_variables
      ENV.select {|env| env =~ /^HOMEBREW_/}
    end

    def homebrew_sha1
      return unless which 'git'
      HOMEBREW_REPOSITORY.cd do
        if File.directory? ".git"
          return `git rev-parse -q --verify refs/remotes/origin/master`.chomp
        end
      end
    end

    def jsonify(series_name, data)
      columns, point = [], []
      data.each {|k,v| columns << k; point << (v || "null") }
      %{[{ "name": "#{series_name}",
           "columns": #{columns.inspect},
           "points": #{[point].inspect} }]}.gsub(/\n/, "").gsub(/\s+/, " ")
    end

    def curl(payload)
      unless ARGV.no_stats?
        url = "http://#{HOST}:#{PORT}/db/#{DATABASE}/series?u=#{USERNAME}&p=#{PASSWORD}"

        puts "[Stats#curl] url: #{url}" if ARGV.verbose?
        puts "[Stats#curl] payload: #{payload}" if ARGV.verbose?

        cmd  = "curl -X POST -H 'Content-Type: application/json'"
        cmd += " -d '#{payload}' '#{url}'"
        cmd += " > /dev/null 2>&1 &"

        puts "[Stats#curl] cmd: #{cmd}" if ARGV.verbose?

        system(cmd)
      end
    end
  end
end
