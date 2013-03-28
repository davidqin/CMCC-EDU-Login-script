require 'nokogiri'
require 'net/http'
require 'uri'
require 'yaml'

class CMCCLogin
  def initialize
    @cmcc_xml_next_url = nil
    @frame_url = nil
    @params = {}
    @post_response = nil
  end

  def connect
    do_task("Getting cmcc xml next url") { get_cmcc_xml_next_url }
    do_task("Getting frame url") { get_frame_url }
    prepare_login_params
    do_task("Login"){ post_login_request }
    do_task("Generate log"){ generate_log }
  end

  def get_cmcc_xml_next_url
    `curl baidu.com`.match(/<NextURL>(.+)<\/NextURL>/)
    @cmcc_xml_next_url = $1.to_s
  end

  def get_frame_url
    first_res = Net::HTTP.get(URI.parse(@cmcc_xml_next_url))
    html = Nokogiri::HTML(first_res)
    xpath = '/html/frameset/frame'
    @frame_url = html.xpath(xpath).first.attribute("src").to_s
  end

  def prepare_login_params
    frame = Net::HTTP.get(URI.parse(@frame_url))
    html = Nokogiri::HTML(frame)

    form = html.xpath("//form[@id='staticloginid']").first

    @params[:action] = form.attribute("action").to_s

    inputs = form.children.css('input')

    inputs.each do |input|
      name = input.attribute("name").to_s
      value = input.attribute("value").to_s

      @params[name] = value
    end

    get_user_and_password
  end

  def get_user_and_password
    yml_file = Dir::pwd + "/cmcc.yml"
    yml = YAML.load_file(yml_file) if File.file?(yml_file)

    return need_input_use_and_password unless yml

    if yml["account"] && yml["account"]["user"] && yml["account"]["password"]
      @params["staticusername"] = yml["account"]["user"]
      @params["staticpassword"] = yml["account"]["password"]
    else
      return need_input_use_and_password
    end
  end

  def need_input_use_and_password
    print "Input User: "
    @params["staticusername"] = gets.chomp
    print "Input Password: "
    @params["staticpassword"] = gets.chomp
  end

  def post_login_request
    @post_response = Net::HTTP.post_form(URI.parse(@params[:action]), @params)
  end

  def generate_log
    html = Nokogiri::HTML(@post_response.body)

    form = html.xpath('//form').first

    puts form.css('h2').first.content.strip
    puts form.css('p').first.content.strip

    f = File.open("cmcc.info", "w")
    action = form.attribute("action").to_s

    inputs = form.children.css('input')

    f.puts action

    inputs.each do |input|
      name = input.attribute("name").to_s
      value = input.attribute("value").to_s
      f.puts name, value , ""
    end

    f.close
  end

  private

  def do_task message
    raise "I need a block!!" unless block_given?
    print message
    yield
    puts "....Done!"
  end
end

CMCCLogin.new.connect
