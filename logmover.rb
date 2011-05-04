#!/usr/bin/env ruby

require 'fileutils'
require 'digest/md5'

LOG_DIR = './test/logs/'
LOG_OLD_DIR = './test/oldlogs/'

# Set to 7 days. Reduce for testing
MAXIMUM_AGE_IN_SECONDS = 7*24*60*60

# Returns all the directories below LOG_DIR
def all_directories dir
  Dir["#{dir}**/"]
end

# Uses an exec to call tar, compressing the folder given as the argument
def compress_directory dir
  if File.directory? dir
    puts "# - Compressing directory: #{dir}"
    dir_compressed_name = dir.sub(".",'').sub("/",'').gsub("/", '_')[0..-2]
    system("tar","-pczf","#{dir_compressed_name}.tar.gz", "#{dir}") if File.exist? dir
    "#{dir_compressed_name}.tar.gz"
  else
    raise "Could not compress the following directory: #{dir}"
  end
end

def directory_age path
  File.stat(path).mtime if File.exist? path
end

# Checks if a directory is older than 7 days, using directory_age
def old_dir? path
  if File.directory? path
    (Time.new - directory_age(path)) >  MAXIMUM_AGE_IN_SECONDS # the difference returns in seconds
  else
    raise "Error while retrieving the directory's age: #{path}"
  end
end

# Attests if the current directory actually contains files, or not.
def contains_files? dir
  contains_files = false
  Dir.entries(dir).each { |entry| contains_files = true if File.file? dir+entry}
  contains_files
end

# Creates the new directory structure under LOG_OLD_DIR in case it doesnt exist.
def move_file (new_directory_path,file)
  FileUtils.mkdir_p new_directory_path  if not File.exist? new_directory_path
  if File.exist? file and File.file? file
    if File.exist? new_directory_path + file
      puts "# - File #{file} already exists. Skipping..."
      FileUtils.rm file
    else
      puts "# - Moving the file: #{file} to #{new_directory_path}..."      
      FileUtils.mv file, new_directory_path
    end
  else
    raise "Error while moving file to #{LOG_OLD_DIR}"
  end
end

def calculate_md5_sum file
  puts "# - Calculating the MD5 sum..."      
  incr_digest = Digest::MD5.new()
  file = File.open file, 'r'
  file.each_line do |line|
    incr_digest << line
  end
  incr_digest
end

if __FILE__ == $0
  puts "# Starting logmover..."
  directories = all_directories LOG_DIR
  puts "# Found #{directories.count} directories in #{LOG_DIR}\n"
  directories.each do |dir| 
    if old_dir? dir  and contains_files? dir
      puts "# Parsing directory: #{dir}"
      f = File.open 'directory_import.log','a'
      begin
        out_file_name = compress_directory dir
        file_md5_sum = calculate_md5_sum out_file_name
        move_file LOG_OLD_DIR + dir[LOG_DIR.length..-1], out_file_name
        f.puts "#{dir};#{out_file_name};#{file_md5_sum};#{Time.new}"
      rescue RuntimeError => error
        puts "Got the following error: #{error}"       
      ensure
        f.close unless f.nil?        
      end
    end
  end
end
