
require 'digest/md5'
require 'active_record'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Account < ActiveRecord::Base
end

class Profile < ActiveRecord::Base
end

set :environment, :production
set :sessions,
  expire_after: 7200,
  secret: 'abcdefghij0123456789'

$page = 0
$select_sex = -1

get '/' do
  redirect '/login'
end

get '/login' do
  erb :loginscr
end

post '/auth' do
  trail_userid = CGI.unescapeElement(CGI.escapeHTML(params[:uid])).truncate(20,omission: '')
  trail_passwd = CGI.unescapeElement(CGI.escapeHTML(params[:pass])).truncate(30,omission: '')

  begin
    a = Account.find(trail_userid)
    db_userid = a.id
    db_salt = a.salt
    db_hashed = a.hashed
    db_algo = a.algo
  rescue
    puts "User #{trail_userid} is not found."
    redirect '/failure'
  end

  if db_algo == "1"
    trail_hashed = Digest::MD5.hexdigest(db_salt + trail_passwd)
  else
    puts "Unknown algolithm is used for user #{trail_userid}."
  end

  if (db_hashed == trail_hashed)
    session[:login_flag] = true
    session[:userid] = db_userid
    redirect '/contentspage'
  else
    session[:login_flag] = false
    redirect '/failure'
  end
end

get '/failure' do
erb :failure
end

get '/contentspage' do
  if (session[:login_flag] == true)
    if $page == 0 then
      $page = 1
    end
    if $select_sex == -1 then
      @f = Profile.all
      @g = Profile.limit(10).offset(10*($page-1))
    elsif $select_sex == 0 then
      @f = Profile.where(sex: 0).all
      @g = Profile.where(sex: 0).limit(10).offset(10*($page-1))
    elsif $select_sex == 1 then
      @f = Profile.where(sex: 1).all
      @g = Profile.where(sex: 1).limit(10).offset(10*($page-1))
    end
    erb :index
  else
    erb :badrequest
  end
end

post '/narrowed_contentspage' do
  trail_sex = params[:narrowed_sex]
  $page = 1

  if trail_sex == "unselect" then
    $select_sex = -1
  elsif trail_sex == "male" then
    $select_sex = 0
  elsif trail_sex == "female" then
    $select_sex = 1
  end

  redirect '/contentspage'
end

post '/next' do
  $page += 1
  redirect '/contentspage'
end

post '/back' do
  if $page >= 1 then
    $page -= 1
  end
  redirect '/contentspage'
end

get '/logout' do
  session.clear
  erb :logout
end

get '/signup' do
  erb :newaccount
end

post '/creation' do
  new_userid = CGI.unescapeElement(CGI.escapeHTML(params[:uid])).truncate(20,omission: '')
  new_passwd = CGI.unescapeElement(CGI.escapeHTML(params[:pass])).truncate(30,omission: '')
  new_name = CGI.unescapeElement(CGI.escapeHTML(params[:name])).truncate(20,omission: '')
  new_age = CGI.unescapeElement(CGI.escapeHTML(params[:age])).truncate(6,omission: '')
  new_message = CGI.unescapeElement(CGI.escapeHTML(params[:message])).truncate(200,omission: '')
  new_email = CGI.unescapeElement(CGI.escapeHTML(params[:email])).truncate(50, '')

  if params[:sex] == "female" then
    new_sex = "1"
  elsif params[:sex] == "male" then
    new_sex = "0"
  elsif params[:sex] == "other" then
    new_sex = "-1"
  end

  r = Random.new
  salt = Digest::MD5.hexdigest(r.bytes(20))

  if Account.find_by(id: new_userid) == nil then
    s = Account.new
    s.id = new_userid
    s.salt = salt
    s.hashed = Digest::MD5.hexdigest(salt + new_passwd)
    s.algo = "1"
    s.save

    t = Profile.new
    t.id = new_userid
    t.name = new_name
    t.sex = new_sex
    t.age = new_age
    t.message = new_message
    t.email = new_email
    t.save

    redirect '/login'
  else
    redirect '/id_suffer'
  end
end

get '/id_suffer' do
  erb :idsuffer
end

get '/change_profile' do
  if (session[:login_flag] == true)
    erb :changeprofile
  else
    erb :badrequest
  end
end

post '/change' do
  nochanged_id = session[:userid]
  changed_name = CGI.unescapeElement(CGI.escapeHTML(params[:name])).truncate(20,omission: '')
  changed_age = CGI.unescapeElement(CGI.escapeHTML(params[:age])).truncate(6,omission: '')
  changed_message = CGI.unescapeElement(CGI.escapeHTML(params[:message])).truncate(200,omission: '')
  changed_email = CGI.unescapeElement(CGI.escapeHTML(params[:email])).truncate(50,omission: '')

  if params[:sex] == "female" then
    changed_sex = "1"
  elsif params[:sex] == "male" then
    changed_sex = "0"
  elsif params[:sex] == "other" then
    changed_sex = "-1"
  end

  u = Profile.find(nochanged_id)
  u.name = changed_name
  u.sex = changed_sex
  u.age = changed_age
  u.message = changed_message
  u.email = changed_email
  u.save

  redirect '/contentspage'
end
