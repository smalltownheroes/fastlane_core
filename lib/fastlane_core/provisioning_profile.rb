module FastlaneCore
  class ProvisioningProfile
    class << self
      # @return (Hash) The hash with the data of the provisioning profile
      # @example
      #  {"AppIDName"=>"My App Name",
      #   "ApplicationIdentifierPrefix"=>["5A997XSAAA"],
      #   "CreationDate"=>#<DateTime: 2015-05-24T20:38:03+00:00 ((2457167j,74283s,0n),+0s,2299161j)>,
      #   "DeveloperCertificates"=>[#<StringIO:0x007f944b9666f8>],
      #   "Entitlements"=>
      #    {"keychain-access-groups"=>["5A997XSAAA.*"],
      #     "get-task-allow"=>false,
      #     "application-identifier"=>"5A997XAAA.net.sunapps.192",
      #     "com.apple.developer.team-identifier"=>"5A997XAAAA",
      #     "aps-environment"=>"production",
      #     "beta-reports-active"=>true},
      #   "ExpirationDate"=>#<DateTime: 2015-11-25T22:45:50+00:00 ((2457352j,81950s,0n),+0s,2299161j)>,
      #   "Name"=>"net.sunapps.192 AppStore",
      #   "TeamIdentifier"=>["5A997XSAAA"],
      #   "TeamName"=>"SunApps GmbH",
      #   "TimeToLive"=>185,
      #   "UUID"=>"1752e382-53bd-4910-a393-aaa7de0005ad",
      #   "Version"=>1}
      def parse(path)
        require 'plist'

        plist = Plist::parse_xml(`security cms -D -i '#{path}'`)
        if (plist || []).count > 5
          plist
        else
          Helper.log.error("Error parsing provisioning profile at path '#{path}'".red)
          nil
        end
      end

      # @return [String] The UUID of the given provisioning profile
      def uuid(path)
        parse(path).fetch("UUID")
      end

      # Installs a provisioning profile for Xcode to use
      def install(path)
        Helper.log.info "Installing provisioning profile..."
        profile_path = File.expand_path("~") + "/Library/MobileDevice/Provisioning Profiles/"
        profile_filename = uuid(path) + ".mobileprovision"
        destination = profile_path + profile_filename

        # If the directory doesn't exist, create it first
        unless File.directory?(profile_path)
          FileUtils.mkdir_p(profile_path)
        end

        if path != destination
          # copy to Xcode provisioning profile directory
          FileUtils.copy(path, destination)
          unless File.exist?(destination)
            raise "Failed installation of provisioning profile at location: '#{destination}'".red
          end
        end
        
        true
      end
    end
  end
end