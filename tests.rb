require 'fileutils'
require 'test/unit'
require 'logmover'

class LogMoverTests < Test::Unit::TestCase

  DIRECTORIES_WITH_LOGS =["./test/logs/2010/01/01/",
                          "./test/logs/2010/01/02/",
                          "./test/logs/2010/02/01/",              
                          "./test/logs/2010/02/02/",
                          "./test/logs/2010/02/03/",
                          "./test/logs/2010/03/01/",
                          "./test/logs/2011/03/02/",
                          "./test/logs/2011/01/01/",
                          "./test/logs/2011/02/01/",
                          "./test/logs/2011/02/02/",
                          "./test/logs/2011/02/03/",
                          "./test/logs/2011/02/04/",
                          "./test/logs/2011/03/02/",]
  EMPTY_DIRECTORIES = ["./test/logs/2010/01/03/",
                       "./test/logs/2010/02/04/",
                       "./test/logs/2011/01/02/",
                       "./test/logs/2011/03/01/",]
                       
  def setup 
    create_test_env
  end

  def teardown 
    remove_test_env
  end
   
  def create_test_env
      DIRECTORIES_WITH_LOGS.each do |dir|
        FileUtils.mkdir_p dir if not File.exist? dir
        # Create random files in the directories above
        3.times do 
          File.open(dir + (0...8).map{65.+(rand(25)).chr}.join, 'w') {|f| f.write("Log File Content\n") }
        end
        # Creates a file with known name in the directory
        File.open(dir + "log.log", 'w') {|f| f.write("Known Content\n") }
      end
      
      # Creates empty directories 
      EMPTY_DIRECTORIES.each do |dir|
       FileUtils.mkdir_p dir if not File.exist? dir
      end
  end
  
  def remove_test_env
    FileUtils.rmtree "./test"
  end
  
  def test_calculate_md5_sum
        md5 = calculate_md5_sum DIRECTORIES_WITH_LOGS[rand(DIRECTORIES_WITH_LOGS.length)]+"log.log"
        assert md5 == "82775acf9c2a6b8302649e0f5941c417"
    end
    
    def test_compress_directory
      dir = DIRECTORIES_WITH_LOGS[rand(DIRECTORIES_WITH_LOGS.length)]
      output_file_name = compress_directory dir
      
      expected_directory_name = dir.sub(".",'').sub("/",'').gsub("/", '_')[0..-2]+".tar.gz"
      assert expected_directory_name == output_file_name
      
      assert File.exist? output_file_name
      FileUtils.rm output_file_name
      
      assert_raises RuntimeError do 
        compress_directory "NONEXISTINGDIR"
      end    
    end
    
    def test_directory_age
           directory_age = directory_age DIRECTORIES_WITH_LOGS[rand(DIRECTORIES_WITH_LOGS.length)]
           assert (Time.new - directory_age) < 5
           directory_age = directory_age EMPTY_DIRECTORIES[rand(EMPTY_DIRECTORIES.length)]
           assert (Time.new - directory_age) < 5
         end
         
       def test_all_directories
         found_directories = all_directories "./test/"
         contains_all = true
         DIRECTORIES_WITH_LOGS.each do |dir|
           contains_all = false if not found_directories.include? dir
         end
         EMPTY_DIRECTORIES.each do |dir|
           contains_all = false if not found_directories.include? dir
         end
         assert contains_all
       end
       
       def test_move_file         
         move_file "./test/", DIRECTORIES_WITH_LOGS[0]+"log.log"
         assert File.exist? "./test/log.log" and not File.exist? DIRECTORIES_WITH_LOGS[0]+"log.log"
         assert_raises RuntimeError do 
           move_file "./test/", "NONEXISTENTFILE"
         end    
       end
end
