require 'rubygems'
require 'mechanize'

class Course
   
    attr_accessor :id, :title, :date_taken

    def initialize(id, title, date_taken)
        @id = id
        @title=title
        @date_taken = date_taken
    end
end

def print_course_table(courses)
    longest_id = courses.max {|left, right| left.id.length <=> right.id.length}
    longest_title = courses.max {|left, right| left.title.length <=> right.title.length}
    result = ""
    courses.each do |course|
        result << sprintf("  %-#{longest_id.id.length}s  %-#{longest_title.title.length}s  %s\n", course.id, course.title, course.date_taken)
    end
    puts result
end

def get_ids
    ids = []
    File.open("ids.txt", "r") do |infile|
        infile.each{|line| ids << line.to_i}
    end
    ids
end


print "Please enter your MyScouting.org username: "
username = gets
print "Please enter your MyScouting.org password: "
system "stty -echo"
password = gets
system "stty echo"

agent = Mechanize.new
login_page = agent.get('https://myscouting.scouting.org/_layouts/MyScouting/login.aspx?ReturnUrl=%2f_layouts%2fAuthenticate.aspx%3fSource%3d%252f&Source=%2f')

login_form = login_page.form('aspnetForm')
login_form['ctl00$PlaceHolderMain$login$UserName'] = username
login_form['ctl00$PlaceHolderMain$login$password'] = password

myscouting_page = agent.submit(login_form, login_form.buttons.first)
 
get_ids.each do |id|
    myscouting_page = agent.get('https://myscouting.scouting.org/Pages/Home.aspx')
    training_page = myscouting_page.link_with(:text => 'Training Validation').click

    validation_form = training_page.form('form1')
    validation_form.field_with(:name => 'MainSearchControl1$ddlDirectSearch').options[1].select
    validation_form.radiobuttons_with(:name => 'MainSearchControl1$rblTrainingSearch')[1].check
    validation_form['MainSearchControl1$txtDirectSearchValue'] = id.to_s

    results_page = agent.submit(validation_form, validation_form.buttons.first)

    person_node = results_page.at('//span[@id="lblResultName"]')
    puts '-------------------------------------------------------'
    if person_node.nil?
        puts "ID #{id} not found."
        next
    end
    puts person_node.text + " (#{id})"
    table = results_page.at('//table[@id="gvTraining"]')
    courses = []
    rows = table.xpath('./tr[position()>1 and position()<last()]')
    rows.each do |row|
        id = row.xpath('./td[1]').text
        title = row.xpath('./td[2]').text
        date_taken = row.xpath('./td[3]').text
        courses << Course.new(id, title, date_taken)
    end
    print_course_table(courses)
end
