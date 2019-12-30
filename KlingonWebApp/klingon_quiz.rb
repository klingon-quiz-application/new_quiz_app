# -*- coding: utf-8 -*-
require 'sinatra'
require 'digest/md5'
require 'active_record'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Account < ActiveRecord::Base
end

class Profile < ActiveRecord::Base
end

class English_word < ActiveRecord::Base
end

class Klingon_word < ActiveRecord::Base
end

class Japanese_word < ActiveRecord::Base
end

set :environment, :production
set :sessions,
  expire_after: 7200,
  secret: 'abcdefghij0123456789'
set :public, File.dirname(__FILE__) + '/public'

# 初期ページ(ログインへ)-----------------------------------------------
get '/' do
  redirect '/login'
end

# ログインページ------------------------------------------------------
get '/login' do
  erb :loginscr
end

# ログイン処理--------------------------------------------------------
post '/auth' do
  trail_userid = CGI.unescapeElement(CGI.escapeHTML(params[:uid])).truncate(20,omission: '')
  trail_passwd = CGI.unescapeElement(CGI.escapeHTML(params[:pass])).truncate(30,omission: '')

  begin
    a = Account.find(trail_userid)
    db_userid   = a.id
    db_salt     = a.salt
    db_hashed   = a.hashed
    db_algo     = a.algo
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

    p = Profile.find(db_userid)
    
    case p.userlang
    when "Japanese" then
      session[:ulang] = Japanese_word
    when "Klingon" then
      session[:ulang] = Klingon_word
    when "English" then
      session[:ulang] = English_word
    end
    
    case p.learnlang
    when "Japanese" then
      session[:llang] = Japanese_word
    when "Klingon" then
      session[:llang] = Klingon_word
    when "English" then
      session[:llang] = English_word
    end
    
    redirect '/mypage'
  else
    session[:login_flag] = false
    redirect '/failure'
  end
end

# ログイン失敗処理-----------------------------------------------------
get '/failure' do
erb :failure
end

# マイページ----------------------------------------------------------
get '/mypage' do
  if (session[:login_flag] == true)
    @f = Profile.find(session[:userid]) # 自分の情報を表示させるため
    session[:page] = 1      # 問題番号を初期化(1から開始)
    erb :mypage
  else
    erb :badrequest
  end
end

# クイズページ--------------------------------------------------------
get '/quiz' do
  loop do
    if session[:ulang].count > session[:llang].count then
      max_count = session[:llang].count
    else
      max_count = session[:ulang].count
    end

    reid = (1 .. max_count).to_a.sort_by{rand}[0..2] # 重複なし乱数3

    if (session[:llang].where(eid: reid[0]).count != 0) &&
       (session[:llang].where(eid: reid[1]).count != 0) &&
       (session[:llang].where(eid: reid[2]).count != 0) &&
       (session[:ulang].where(eid: reid[0]).count != 0) &&
       (session[:ulang].where(eid: reid[1]).count != 0) &&
       (session[:ulang].where(eid: reid[2]).count != 0) then
      @r3 = (0 .. 2).to_a.sort_by{rand}[0..2] # 重複なし乱数3
  
      @ansA = session[:ulang].where(eid: reid[@r3[0]])
      @ansB = session[:ulang].where(eid: reid[@r3[1]])
      @ansC = session[:ulang].where(eid: reid[@r3[2]])

      session[:quiz_id] = reid[rand(0..2)] # 正解のeid
  
      @question_record = session[:llang].where(eid: session[:quiz_id])
      break
    end
  end
  
  erb :quiz
end

# 正解判定------------------------------------------------------------
post '/judgment' do
  upr = Profile.find(session[:userid]) # User's profile record
  upr.qc += 1
  
  judg_flag = CGI.unescapeElement(CGI.escapeHTML(params[:uans])).truncate(20,omission: '')
  
  if (judg_flag.to_i == session[:quiz_id].to_i) then
    upr.cc += 1 # 正答数をインクリメント
    upr.rate = (upr.cc.to_f / upr.qc.to_f) * 100
    upr.save
    redirect '/correct'
  else
    upr.rate = (upr.cc.to_f / upr.qc.to_f) * 100
    upr.save
    redirect '/incorrect'
  end
  
end

# 正解ページ----------------------------------------------------------
get '/correct' do
  @correct_record = session[:ulang].where(eid: session[:quiz_id])
  @question_record = session[:llang].where(eid: session[:quiz_id])
  erb :correct
end

# 不正解ページ---------------------------------------------------------
get '/incorrect' do
  @correct_record = session[:ulang].where(eid: session[:quiz_id])
  @question_record = session[:llang].where(eid: session[:quiz_id])
  erb :incorrect
end

# 次の問題へ-----------------------------------------------------------
post '/next' do
  session[:page] += 1
  redirect '/quiz'
end

# ランキング-----------------------------------------------------------
get '/ranking' do
  @rkg = Profile.limit(10).order(rate: "DESC")
  erb :ranking
end

# ログアウト-----------------------------------------------------------
get '/logout' do
  session.clear
  erb :logout
end

get '/signup' do
  erb :newaccount
end

post '/creation' do
  # Account,Profile入力
  new_userid = CGI.unescapeElement(CGI.escapeHTML(params[:uid])).truncate(20,omission: '')
  new_passwd = CGI.unescapeElement(CGI.escapeHTML(params[:pass])).truncate(30,omission: '')
  new_name = CGI.unescapeElement(CGI.escapeHTML(params[:name])).truncate(20,omission: '')
  new_age = CGI.unescapeElement(CGI.escapeHTML(params[:age])).truncate(6,omission: '')
  new_message = CGI.unescapeElement(CGI.escapeHTML(params[:message])).truncate(200,omission: '')
  new_email = CGI.unescapeElement(CGI.escapeHTML(params[:email])).truncate(50, '')

  # 性別
  if params[:sex] == "female" then
    new_sex = "1"
  elsif params[:sex] == "male" then
    new_sex = "0"
  elsif params[:sex] == "other" then
    new_sex = "-1"
  end

  # 使用言語と学習言語
  new_userlang  = params[:ulang]
  new_learnlang = params[:llang]
  
  # 問題数とか正答数とかそのあたりの初期化
  new_qc   = 0
  new_cc   = 0
  new_rate = nil

  # ソルト計算
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
    t.userlang = new_userlang
    t.learnlang = new_learnlang
    t.qc = new_qc
    t.cc = new_cc
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

  # 性別
  if params[:sex] == "female" then
    changed_sex = "1"
  elsif params[:sex] == "male" then
    changed_sex = "0"
  elsif params[:sex] == "other" then
    changed_sex = "-1"
  end

  # 使用言語と学習言語
  changed_userlang  = params[:ulang]
  changed_learnlang = params[:llang]

  u = Profile.find(nochanged_id)
  u.name      = changed_name
  u.sex       = changed_sex
  u.age       = changed_age
  u.message   = changed_message
  u.email     = changed_email
  u.userlang  = changed_userlang
  u.learnlang = changed_learnlang
  u.save

  # 言語データベースのセッション更新
  case u.userlang
  when "Japanese" then
    session[:ulang] = Japanese_word
  when "Klingon" then
    session[:ulang] = Klingon_word
  when "English" then
    session[:ulang] = English_word
  end
    
  case u.learnlang
  when "Japanese" then
    session[:llang] = Japanese_word
  when "Klingon" then
    session[:llang] = Klingon_word
  when "English" then
    session[:llang] = English_word
  end

  redirect '/mypage'
end
