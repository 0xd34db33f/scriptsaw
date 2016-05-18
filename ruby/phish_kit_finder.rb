#!/usr/bin/env ruby
# phish_kit_finder.rb
# Ryan C. Moon
# 2016-03-09
# Hunts for phishing kits at the provided url.

# libs
require 'rest-client'
require 'json'

# consts
DEBUG=0
VERSION="0.1"
USER_AGENT="Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET4.0E; .NET4.0C)"
KIT_FILENAMES = ['dropbox.zip','sparskss.zip','dpbx.zip','wells3x.zip','secureLogin_3.zip','administrator.zip','ipaad.zip','msn.zip','wellsfargo.zip','bookmark.zip','Dropbox.zip','www.zip','hotmail.zip','update.zip','xnowxoffnowxnowoffhd.zip','global.zip','docx.zip','support-Verification.zip','estatspark.zip','login.zip','ipad.zip','scampage.zip','s.p.zip','Arch.zip','filez.zip','irs.zip','gdoc.zip','phone.zip','nD.zip','db.zip','adobe.zip','FOX.zip','usaa.zip','GD.zip','itunes.appel.com.zip','DROPBOX%20MEN..zip','BDB.zip','yahoo.zip','update_info-paypal-tema-login-update_info-paypal-tema-login-update_info-paypal-tema-loginhome.zip','outlook.zip','icscards:nl.zip','googledocs.zip','alibaba.zip','www.kantonalbank.ch.zip','wes.zip','google.zip','Zone1.zip','BDBB.zip','Aol-Login.zip','live.com.zip','gmail.zip','drpbx%20-%20Copy.zip','Google.zip','GD1.zip','BiyiBlaze.zip','BDBBB4.zip','Aolnew.zip','wells.zip','web.zip','validation.zip','usaa_com.zip','servelet_usaa.zip','order.zip','home.zip','document.zip','chase.zip','app.zip','BOBI.zip','maxe.zip','max.zip','googledrive.zip','googledoc.zip','general.zip','filedrop.zip','dr.zip','doc.zip','access.zip','Yahoo.zip','Yahoo-2014.zip','DropBoxDocument.zip','www.hypovereinsbank.de.zip','www.citibank.com.my.zip','undoo.zip','tesco.zip','spass.zip','outlook%20True..zip','myposte.zip','hvsf.zip','gmez.zip','global2.zip','dpp.zip','Usaa.zip','R-viewdoc.zip','Pamilerinayooluwa.zip','Ourtime.zip','Hotmail-New.zip','DHL.zip','Adobe.zip','wp-admin.zip','westpac.zip','wellsfargo.com.zip','welcome.zip','suite.zip','spaskas.zip','signontax.zip','share.zip','script1.zip','santander.zip','rr.zip','online.zip','new.zip','new%20google%20doc..zip','dropboxLanre.zip','drive.zip','docs.zip','db2.zip','christain_mingle.zip','aol.zip','Investor.zip','G6.zip','BILLIONS%20PAGE..zip','yahoo.com.zip','ww.zip','ups.zip','outlooknew.zip','finance.zip','files.zip','dropbox1..zip','dropbox%20LoginVerification%20-prntscr.com-9sjlf0.zip','dhl.zip','db2016.zip','css.zip','commbankonlineau.zip','box.zip','bof.zip','bbooffaa.zip','auth.inet.ent_Logon-redirectjsp.true.zip','art.zip','admin.zip','accounts.zip','LIFEVERIFY.zip','IRS.zip','GOG.zip','Dropbox1..zip','Doc.zip','DROPBOX','Business.zip','8-login-form.zip','1.zip','wllxzccc.zip','webmail.zip','vivt.zip','validate.zip','spar.zip','royalbank.zip','review.zip','rebuilt.gdoc.zip','obiora.zip','news.zip','match2.zip','maildoc.zip','google%20dariver%202015.zip','good.zip','gee.zip','dropelv.%20-%20Copy.zip','dropbox2016.zip','dropbl.zip','dpx.zip','dm.zip','db2011.zip','class.zip','ch.zip','capitalone360.zip','apple.zip','aoljunior.zip','PDP..zip','Nuvo.zip','Newdropbox15-1.zip','Gouv_lmpouts.zip','Gmail.zip','Gdoc.zip','Fresh.zip','Ed.zip','DROPBOX.zip','3.0.zip','gdocs.zip','gdocs1.zip','GD.zip','art3..zip']

# defs
def usage(message)
  print "#{message}\n\n" unless message.empty?
  
  print "phish_kit_finder.rb \n"
  print "GPLv3 - 2016-03-09 \n"
  print "by Ryan C. Moon (@ryancmoon|ryan@organizedvillainy.com) \n"
  print "\n"
  print "Usage: ./phish_kit_finder.rb <BASEURL> \n"

  abort()
end

def get_url(url)
  print "[attempt] GETing #{url}\n" if DEBUG > 0
  results = ""
  
  begin 
    results = RestClient.get url,{ :accept => :json, :content_type => :json, :user_agent => USER_AGENT }
  rescue RestClient::ResourceNotFound => error
    # skip 404's we don't care.
    return false
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{url}. Exception: #{error.inspect} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{url}. Exception: #{error.inspect} \n"
    abort()
  end
  
  (results.code == 200) ? true : false
end

# go
usage("Error parsing command line options") if ARGV.size != 1
usage("Error parsing URL argument:#{ARGV[0]}") unless ARGV[0].match(/^https?:\/\//)

# trim any trailing /'s
url = ARGV[0]
url = url.chomp if url.match(/\/$/)

# Loop through kit names looking for kits.
found = false
KIT_FILENAMES.each do |name|
  next if found
  kit_url = url + "/" + name
  if get_url(kit_url)
    found = true
    print "Kit found: #{kit_url} \n"
  end
end

# boo we didn't find anything
print "BOO! No kits found for base_url: #{url}..\n" if !found
  
  
  
