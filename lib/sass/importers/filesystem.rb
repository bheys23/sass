module Sass
  module Importers
    # The default importer, used for any strings found in the load path.
    # Simply loads Sass files from the filesystem using the default logic.
    class Filesystem < Base
      # Creates a new filesystem importer that imports files relative to a given path.
      #
      # @param root [String] The root path.
      #   This importer will import files relative to this path.
      def initialize(root)
        @root = root
      end

      # @see Base#find_relative
      def find_relative(name, base, options)
        _find(File.dirname(base), name, options)
      end

      # @see Base#find
      def find(name, options)
        _find(@root, name, options)
      end

      # @see Base#to_s
      def to_s
        @root
      end

      protected

      # A hash from file extensions to the syntaxes for those extensions.
      # The syntaxes must be `:sass` or `:scss`.
      #
      # This can be overridden by subclasses that want normal filesystem importing
      # with unusual extensions.
      #
      # @return [{String => Symbol}]
      def extensions
        {'sass' => :sass, 'scss' => :scss}
      end

      # Given an `@import`ed path, returns an array of possible
      # on-disk filenames and their corresponding syntaxes for that path.
      #
      # @param name [String] The filename.
      # @return [Array(String, Symbol)] An array of pairs.
      #   The first element of each pair is a filename to look for;
      #   the second element is the syntax that file would be in (`:sass` or `:scss`).
      def possible_files(name)
        dirname, basename, extname = File.dirname(name), File.basename(name), File.extname(name)
        extname.slice!(0)
        sorted_exts = extensions.sort
        syntax = extensions[extname]

        Haml::Util.flatten(
          ["#{dirname}/#{basename}", "#{dirname}/_#{basename}"].map do |name|
            next [[name, syntax]] if syntax
            sorted_exts.map {|ext, syn| ["#{name}.#{ext}", syn]}
          end, 1)
      end

      # Given a base directory and an `@import`ed name,
      # finds an existant file that matches the name.
      #
      # @param dir [String] The directory relative to which to search.
      # @param name [String] The filename to search for.
      # @return [(String, Symbol)] A filename-syntax pair.
      def find_real_file(dir, name)
        possible_files(name).each do |f, s|
          if File.exists?(full_path = "#{dir}/#{f}")
            return full_path, s
          end
        end
        nil
      end

      private

      def _find(dir, name, options)
        full_filename, syntax = find_real_file(dir, name)
        return unless full_filename && File.readable?(full_filename)

        options[:syntax] = syntax
        options[:filename] = full_filename
        options[:importer] = self
        Sass::Engine.new(File.read(full_filename), options)
      end
    end
  end
end
