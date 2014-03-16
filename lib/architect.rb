require 'rubygems'
require 'nokogiri'
require 'open-uri'
 class Architect
   @@filepath = nil
   def self.filepath=(path=nil)
     @@filepath = File.join(APP_ROOT, path)
   end

   attr_accessor  :email, :practice

   def self.file_exists?
     # class should know if the architect file exists
     if @@filepath && File.exists?(@@filepath)
       return true
     else
       return false
     end
   end

   def self.file_usable?
     return false unless @@filepath
     return false unless File.exists?(@@filepath)
     return false unless File.readable?(@@filepath)
     return false unless File.writable?(@@filepath)
     return true
   end

   def self.create_file
     # create the architect file
     File.open(@@filepath, 'w') unless file_exists?
     return file_usable?
   end

   def self.saved_architects
     # We have to ask ourselves, do we want a fresh copy each 
     # time or do we want to store the results in a variable?
     architects = []
     if file_usable?
       file = File.new(@@filepath, 'r')
       file.each_line do |line|
         architects << Architect.new.import_line(line.chomp)
       end
       file.close
     end
     return architects
   end

   def self.build_using_questions
     args = {}

     print "Architect's Register number "
     args[:regno] = gets.chomp.strip

     print "Architect title: "
     args[:title] = gets.chomp.strip

     print "Architect is known as: "
     args[:fname] = gets.chomp.strip

     print "Architect's last name: "
     args[:lname] = gets.chomp.strip

     print "Architect's website: "
     args[:website] = gets.chomp.strip

     print "Architect's email: "
     args[:email] = gets.chomp.strip

     print "Architect's location: "
     args[:city] = gets.chomp.strip

     print "Architect's Practice name: "
     args[:practice] = gets.chomp.strip
     return self.new(args)
   end
   
   def self.receive(practice, email)
    args = {}
     
     if email == ""
       return nil
     else
       args[:practice] = practice
       args[:email] = email
       #args[:regno] = reg_no
       #test = doc.xpath('//td//table[(((count(preceding-sibling::*) + 1) = 2) and parent::*)]//td/text()').text
       return self.new(args)
     end    
   end

   def initialize(args={})
     #@regno = args[:regno]   || "nil"
     #@title = args[:title]    || "nil"
     #@fname = args[:fname] || "nil"
     #@lname = args[:lname]   || "nil"
     #@status = args[:status]   || "nil"
     #@website = args[:website]   || "nil"
     @practice = args[:practice]   || "nil"
     @email = args[:email]   || "nil"
     #@city = args[:city]   || "nil"
     
   end

   def import_line(line)
     line_array = line.split("\t")
     @practice, @email = line_array
     return self
   end

   def save
     return false unless Architect.file_usable?
     File.open(@@filepath, 'a') do |file|
       file.puts "#{[@practice, @email].join("\t")}\n"
        return true
     end    
   end  
 end 