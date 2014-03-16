require 'architect'
require 'support/string_extend'
require 'rubygems'
require 'gmail'
require 'nokogiri'
require 'open-uri'


class Guide
  
  class Config
    @@actions = ['send', 'list', 'find', 'add', 'scrap', 'quit']
    def self.actions; @@actions; end
  end
  
  def initialize(path=nil)
    # locate the architect text file at path
    Architect.filepath = path
    if Architect.file_usable?
      puts "Found architect file."
    # or create a new file
    elsif Architect.create_file
      puts "Created architect file."
    # exit if create fails
    else
      puts "Exiting.\n\n"
      exit!
    end
  end

  def launch!
    introduction
    # action loop
    result = nil
    until result == :quit
      action, args = get_action
      result = do_action(action, args)
    end
		conclusion
  end
  
  def get_action
    action = nil
    # Keep asking for user input until we get a valid action
    until Guide::Config.actions.include?(action)
      puts "Actions: " + Guide::Config.actions.join(", ")
      print "> "
      user_response = gets.chomp
      args = user_response.downcase.strip.split(' ')
      action = args.shift
    end
    return action, args
  end
  
  def do_action(action, args=[]) 
    case action
    when 'send'
      send_mail
    when 'list'
      list(args)
    when 'find'
      keyword = args.shift
      find(keyword)
    when 'add'
      add
    when 'scrap'
      scrap
    when 'quit'
      return :quit
    else
      puts "\nI don't understand that command.\n"
    end
  end

  def list(args=[])
    sort_order = args.shift 
    sort_order = args.shift if sort_order == 'by'
    sort_order = "regno" unless ['regno', 'title', 'fname', 'lname', 'website', 'email', 'city', 'practice'].include?(sort_order)
    
    output_action_header("Listing architects")
    
    architects = Architect.saved_architects
    architects.sort! do |r1, r2|
      case sort_order
      when 'regno'
      r1.regno.downcase <=> r2.regno.downcase
      when 'title'
        r1.title.downcase <=> r2.title.downcase
      when 'fname' 
       r1.fname.downcase <=> r2.fname.downcase
      when 'lname' 
      r1.lname.downcase <=> r2.lname.downcase
      when 'website' 
       r1.website.downcase <=> r2.website.downcase
      when 'email' 
       r1.email.downcase <=> r2.email.downcase
      when 'city' 
       r1.city.downcase <=> r2.city.downcase
      when 'practice' 
       r1.practice.downcase <=> r2.practice.downcase
      end  
    end
    output_architect_table(architects)
    puts "\nSort using: 'list email' or 'list by email'\n\n"
  end
  
  def find(keyword="")
    output_action_header("Find a architect")
    if keyword
      # search
      architects = Architect.saved_architects
      found = architects.select do|rest| 
        rest.name.downcase.include?(keyword.downcase) ||
        rest.cuisine.downcase.include?(keyword.downcase) ||
        rest.price.to_i <= keyword.to_i
      end
      output_architect_table(found)
    else
      puts "Find using a key phrase to search the architect list"
      puts "Examples: 'find mex'\n\n"
    end
  end
  
  def add
    output_action_header("Add an architect")
    @architect = Architect.build_using_questions
    save_architect
  end
  
  def scrap
    output_action_header("Add an architect")
    page_no = 186
    #@reg_no =  url_regno
    until page_no == 4500 do
      table_index_no = 2
      
      url = "http://www.architecture.com.au/adabd_search?option=show&t=1271583128&pg=#{page_no}&sb=1"
      doc = Nokogiri::HTML(open(url))
      
      
      until table_index_no == 12 do
        practice = doc.xpath("//td//table[(((count(preceding-sibling::*) + 1) = #{table_index_no}) and parent::*)]//td[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]//b/text()").text 
        email = doc.xpath("//td//table[(((count(preceding-sibling::*) + 1) = #{table_index_no}) and parent::*)]//*[contains(concat( ' ', @class, ' ' ), concat( ' ', 'bodytext', ' ' ))]//a[(((count(preceding-sibling::*) + 1) = 1) and parent::*)]/text()").text
        @architect = Architect.receive(practice, email)
        if @architect.nil?
          puts "\n - Save Error: Architect skipped\n"
        else
          save_architect
        end
        table_index_no += 1 
      end
       page_no += 1
    end
  end
  
  def introduction
    puts "\n\n<<< Welcome to the NZRAB Registred Architects List >>>\n\n"
  end

	def conclusion
  	puts "\n<<< Goodbye >>>\n\n\n"
	end
	
	def send_mail(args=[])
	  architects = Architect.saved_architects

	  architects.each do |arch|
	    gmail = Gmail.new("login", "passwd")

      new_email = gmail.new_message
      new_email.to "#{arch.email}"
      new_email.subject "To #{arch.practice}"
      plain, html = new_email.generate_multipart('text/plain', 'text/html') 
      
      if arch.practice != "nil"
        a = arch.practice
      else
        a = "your business"
      end
      
      plain.content = "
      "

      html.content = "
        <html xmlns='http://www.w3.org/1999/xhtml'>
        <body>
        <table width='550' cellpadding='0' cellspacing='0' bgcolor='#FFFFFF'>
          <tr>
            <td bgcolor='#FFFFFF' valign='top' style='font-size:14px;color:#000000;line-height:140%;font-weight:normal;font-family:baskerville, times, sans-serif;margin: 15px auto;padding: 15px;'>

              <p>Dear #{arch.title.titleize + ' ' + arch.fname.titleize + ' ' + arch.lname.titleize},</p>
              <p>I have found #{a} contact at NZRAB website ....</p>
              <p> ... TEXT ...</p>
          </td>
          </tr>
        </table>
        </html>"
      #new_email.attach_file('document.doc')
      #new_email.attach_file('pdf.pdf')
      gmail.send_email(new_email) 
      
      puts "-------Email has been sent to #{arch.practice}--------" 
      
      puts Time.now
      #sleep 20
      
	  end
  
  end
	
	
	private
	
	def save_architect
	  if @architect.save
      puts "\n - Architect Added\n\n"
    else
      puts "\nSave Error: Architect cannot be saved\n\n"
    end 
  end
	
	def output_action_header(text)
	  puts "\n#{text.upcase.center(60)}\n\n"
	end
	
	def output_architect_table(architects=[])
    print " " + "No".ljust(8)
    print " " + "Name".ljust(20)
    #print " " + "Website".ljust(20)
    print " " + "Email".ljust(20)
    print " " + "City".rjust(10) + "\n"
    puts "-" * 60
    architects.each do |rest|
      line =  " " << rest.regno.ljust(8)
      line << " " + rest.title.titleize + ' ' + rest.fname.titleize + ' ' + rest.lname.titleize.ljust(10)
      #line << " " + rest.website.ljust(20)
      line << " " + rest.email.ljust(20)
      line << " " + rest.city.rjust(10)
      puts line
    end
    puts "No listings found" if architects.empty?
    puts "-" * 60
  end
  
end