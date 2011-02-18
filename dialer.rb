require "yaml"
require "adhearsion"
require "adhearsion/voip/asterisk/manager_interface"
require "faster_csv"

class Dialer
  # You need this to run the application as standalone
  include Adhearsion::VoIP::Asterisk::Manager

  # this will accept a csv= parameter for your list
  def initialize(args)
    @lead_source = args[:csv]
    load_config
    connect_ami true
  end

  # this method will be the major runner of all things
  def self.start
    # start parsing the list
    FasterCSV.foreach(@lead_source, :quote_char => '"', :col_sep => ';', :row_sep => :auto) do |row|
      dial(row)
    end
  end

  def self.dial(lead)
    # prepare options for parameters in originate command
    options = {
      :channel  => @config['channel'],
      :context  => @config['context'],
      :exten    => @config['exten'],
      :priority => @config['priority'],
      :timeout   => @config['timeout'],
      :callerid => @config['callerid']
    }

    # best practice to do try-catch
    begin
      @response = @asterisk.send_action "Originate", options
    rescue Adhearsion::VoIP::Asterisk::Manager::ManagerInterfaceError => error
      puts error
    end

  end

  private
  # Method use to load config.yml file contents into variables
  def load_config
    @config = YAML.load_file File.expand_path(File.dirname(__FILE__) + "config.yml")
  end

  # creates @asterisk variable that contains the AMI Connection for re-use
  # i use connect=false as default specially for testing
  def connect_ami(connect=false)
    if connect 
      @asterisk = ManagerInterface.connect :host => @config['ami_host'],
        :username => @config['ami_user'],
        :password => @config['ami_pass'],
        :events => @config['ami_events']
    end
  end

end

