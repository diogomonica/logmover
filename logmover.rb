#!/usr/bin/env ruby

require 'fileutils'
require 'digest/md5'

@log_dir = '/tmp/logs/'
@log_old_dir = '/tmp/oldlogs/'

# Set to 7 days. Reduce for testing
@maximum_age_in_seconds = 7*24*60*60

# Returns all the directories below @log_dir
def get_all_directories
  Dir["#{@log_dir}**/"]
end

# Uses an exec to call tar, compressing the folder given as the argument
def compress_directory (dir)
  if File.directory? dir
    puts "# - Compressing directory: #{dir}"
    dir_compressed_name = dir.sub("/",'').gsub("/", '_')[0..-2]
    system("tar -pczf #{dir_compressed_name}.tar.gz #{dir} >> /dev/null") if File.exist? dir
    "#{dir_compressed_name}.tar.gz"
  else
    raise "Could not compress the following directory: #{dir}"
  end
end

# There is no way of getting the age of a directory in Linux. 
# This method returns the age of the most recent file in the directory
def get_directory_age (path)
  if File.directory? path
    newest_timestamp = Time.at(0)
    Dir["#{path}*"].each { |file| newest_timestamp = File.stat(file).atime if File.stat(file).atime > newest_timestamp }

    # If the timestamp is unchanged, the directory is empty.
    # Return Time.now so it will pass the ignore logic
    if newest_timestamp == Time.at(0)
      Time.now
    else
      newest_timestamp
    end
  end
end

# Checks if a directory is older than 7 days, using get_directory_age
def old_dir? (path)
  if File.directory? path
    (Time.new - get_directory_age(path)) >  @maximum_age_in_seconds# the difference returns in seconds
  else
    raise "Error while getting the directory's age: #{path}"
  end
end

# Creates the new directory structure under @log_old_dir in case it doesnt exist.
# Moves a file to the @old_log_dir directory. 
def move_file_to_old_log_dir (file,dir)
  new_directory_path = @log_old_dir + dir[@log_dir.length..-1]
  FileUtils.mkdir_p(new_directory_path) if not File.exist? new_directory_path
  if File.exist? file and File.file? file
    if File.exist? new_directory_path + file
      puts "# - File #{file} already exists. Skipping..."
    else
      puts "# - Moving the file: #{file} to #{@log_old_dir}..."      
      FileUtils.mv(file, new_directory_path)
    end
  else
    raise "Error while moving file to #{@log_old_dir}"
  end
end

def calculate_md5_sum (file)
  puts "# - Calculating the MD5 sum..."      
  incr_digest = Digest::MD5.new()
  file = File.open(file, 'r')
  file.each_line do |line|
    incr_digest << line
  end
  incr_digest
end

puts "# Starting logmover..."
directories = get_all_directories
puts "# Found #{directories.count} directories in #{@log_dir}\n"
directories.each do |dir| 
  if old_dir? dir
    puts "# Parsing directory: #{dir}"
    f = File.open('directory_import.log','a')
    begin
      out_file_name = compress_directory(dir)
      file_md5_sum = calculate_md5_sum(out_file_name)
      move_file_to_old_log_dir(out_file_name, dir)
      f.puts "#{out_file_name};#{file_md5_sum}"
    rescue RuntimeError => error
      puts "Got the following error: #{error}" 
      f.puts "Got the following error: #{error}" 
    ensure
      f.close unless f.nil?        
    end
  end
end