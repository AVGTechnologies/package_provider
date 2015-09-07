require 'zip'

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
          entries = Dir.entries(File.join(input_dir, src)) - %w(. ..)
          write_entries File.join(input_dir, src), entries, dest, io
        end
      end

      @output_file
    end

    private

    # A helper method to make the recursion work.
    def write_entries(input_dir, entries, path, io)
      entries.each do |e|
        zip_file_path = File.join(path, e)
        disk_file_path = File.join(input_dir, e)
        # puts "Deflating #{disk_file_path} into #{zip_file_path}"

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
        while buff = fr.read(BUFF_SIZE)
          f.write(buff)
        end
        fr.close
      end
    end
  end
end
