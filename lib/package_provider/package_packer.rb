require 'package_provider/zip_file_generator'
# zip ruby performance
# http://blog.huangzhimin.com/2012/10/02/avoid-using-rubyzip/
module PackageProvider
  # class managing packing package
  class PackagePacker
    attr_reader :dest_dir

    def initialize(dest_dir, file_name = 'package.zip')
      fail ArgumentError, 'dest_dir is required' unless dest_dir
      @dest_dir = dest_dir
      @zip_generator = ZipFileGenerator.new(File.join(@dest_dir, file_name))
    end

    def add_folder(src_dir, folder_override)
      @zip_generator.add_folder(
        src_dir, folder_override.source, folder_override.destination)
    end

    def flush
      @zip_generator.write
    end
  end
end
