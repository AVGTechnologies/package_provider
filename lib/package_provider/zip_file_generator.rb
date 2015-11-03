require 'zip'
require 'pathname'

module PackageProvider
  # Class for recursively generate a zip file from the contents of
  # a specified directory.
  class ZipFileGenerator
    BUFF_SIZE = 4096
    # Initialize with the dir to zip and the location of the output archive.
    #
    # @param [String, #output_file] path whrere to create a zip archive
    def initialize(output_file)
      @output_file = output_file
      @folders = []
    end

    # Stores information about folder to be zipped
    #
    # @param [String, #input_dir] path to src
    # @param [String, #src] folder to add into archive
    # @param [String, #dest] path in archive
    def add_folder(input_dir, src, dest)
      @folders << [input_dir, src, dest]
    end

    # Zip the input directory
    #
    # @return [String] complete path to final zip archive
    def write
      ::Zip::File.open(@output_file, ::Zip::File::CREATE) do |io|
        @folders.each do |input_dir, src, dest|
          path = source(File.join(input_dir, src))
          write_entries(path, entries(src, input_dir), dest, io)
        end
      end

      @output_file
    end

    private

    # A helper method to make the recursion work.
    def write_entries(input_dir, entries, path, io)
      entries.each do |e|
        disk_file_path = File.join(input_dir, e)
        zip_file_path = zip_file_path(path, e, input_dir)
        PackageProvider.logger.debug(
          "Deflating #{disk_file_path} into #{zip_file_path}")

        if File.directory? disk_file_path
          recursively_deflate_directory(disk_file_path, io, zip_file_path)
        else
          put_into_archive(disk_file_path, io, zip_file_path)
        end
      end
    end

    def recursively_deflate_directory(disk_file_path, io, zip_file_path)
      io.mkdir zip_file_path
      subdir = Dir.entries(disk_file_path) - %w(. ..)
      write_entries disk_file_path, subdir, zip_file_path, io
    end

    def put_into_archive(disk_file_path, io, zip_file_path)
      io.get_output_stream(zip_file_path) do |f|
        fr = File.open(disk_file_path, 'rb')
        # rubocop:disable AssignmentInCondition
        while buff = fr.read(BUFF_SIZE)
          f.write(buff)
        end
        # rubocop:enable AssignmentInCondition
        fr.close
      end
    end

    def entries(src, input_dir)
      pn = Pathname.new(File.join(input_dir, src))
      if pn.directory?
        Dir.entries(File.join(input_dir, src)) - %w(. ..)
      else
        [pn.basename]
      end
    end

    def source(src)
      pn = Pathname.new(src)
      return pn.dirname unless pn.directory?
      src
    end

    def zip_file_path(path, entry, input_dir)
      return entry.dup unless path
      pn = Pathname.new(File.join(input_dir, path, entry))
      pn.directory? ? path : File.join(path, entry)
    end
  end
end
