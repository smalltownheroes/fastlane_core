module FastlaneCore
  # Responsible for loading configuration files
  class ConfigurationFile
    # A reference to the actual configuration
    attr_accessor :config

    # @param config [FastlaneCore::Configuration] is stored to save the resulting values
    # @param path [String] The path to the configuration file to use
    def initialize(config, path, block_for_missing)
      self.config = config
      @block_for_missing = block_for_missing

      begin
        # rubocop:disable Lint/Eval
        eval(File.read(path)) # this is okay in this case
        # rubocop:enable Lint/Eval
      rescue SyntaxError => ex
        if ex.to_s.include? "‘"
          Helper.log.fatal ex
          raise "Invalid quotation: You used the invalid quote ‘ instead of '. Make sure to use a good text editor like Sublime Text to edit your configuration file".red
        else
          line = ex.to_s.match(/\(eval\):(\d+)/)[1]
          raise "Syntax error in your configuration file '#{path}' on line #{line}: #{ex}".red
        end
      end
    end

    def method_missing(method_sym, *arguments, &block)
      # First, check if the key is actually available
      if self.config.all_keys.include? method_sym
        value = arguments.first || (block.call if block_given?) # this is either a block or a value
        if value
          self.config[method_sym] = value
        end
      else
        # We can't set this value, maybe the tool using this configuration system has its own
        # way of handling this block, as this might be a special block (e.g. ipa block) that's only
        # executed on demand
        if @block_for_missing
          @block_for_missing.call(method_sym, arguments, block)
        else
          self.config[method_sym] = '' # important, since this will raise a good exception for free
        end
      end
    end
  end
end
