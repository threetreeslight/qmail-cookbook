#
# Cookbook Name:: qmail
# Recipe:: default
#
# ae06710 / ThreeTreesLight
#

# include yum::default
# 
# yum_repository "opensuse" do
#   url "http://download.opensuse.org/repositories/home:/weberho:/qmailtoaster/CentOS_5/home:weberho:qmailtoaster.repo"
#   action :add
# end

## group, usr, dir
#
directory '/var/qmail' do
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
end

%w{ nofiles qmail }.each do |grp|
  group grp do
    group_name grp
    action     [:create]
  end
end

user 'alias' do
  comment  'alias'
  group    'nofiles'
  home     '/var/qmail/alias'
  shell    '/bin/false'
  password nil
  supports :manage_home => true
  action   [:create, :manage]
end

%w{ qmaild qmaill qmailp }.each do |usr|
  user usr do
    comment  usr
    group    'nofiles'
    home     '/var/qmail'
    shell    '/bin/false'
    password nil
    supports :manage_home => true
    action   [:create, :manage]
  end
end

%w{ qmailq qmailr qmails }.each do |usr|
  user usr do
    comment  usr
    group    'qmail'
    home     '/var/qmail'
    shell    '/bin/false'
    password nil
    supports :manage_home => true
    action   [:create, :manage]
  end
end

bash 'download_qmail' do
  cwd '/usr/local/src'
  user 'root'
  group 'root'
  code <<-EOC
    wget http://qmail.teraren.com/netqmail-1.06.tar.gz
    tar xvfz netqmail-1.06.tar.gz
  EOC
  creates "/usr/local/src/netqmail-1.06"
end

bash 'install_qmail' do
  cwd '/usr/local/src/netqmail-1.06'
  user 'root'
  group 'root'
  code <<-EOC
    sudo make setup
    sudo make check
    sudo ./config-fast #{node['qmail']['domain']}
  EOC
  creates "/usr/local/src/netqmail-1.06/config-fast"
end

bash 'setting_qmail' do
  cwd '/var/qmail/alias'
  user 'root'
  group 'root'
  code <<-EOC
    sudo touch .qmail-postmaster .qmail-mailer-daemon .qmail-root
    chmod 644 .qmail*
    cp /var/qmail/boot/home /var/qmail/rc
    sed -i 's/Mailbox/Maildir\//g' /var/qmail/rc
  EOC
  creates "/var/qmail/rc"
end

template "/etc/init.d/qmail" do
  source 'qmail.erb'
  mode '0755'
end
template "/usr/local/bin/qmail" do
  source 'qmail.erb'
  mode '0755'
end

## Maildir
#
bash 'create root Maildir' do
  user 'root'
  group 'root'
  code <<-EOC
    /var/qmail/bin/maildirmake ~alias/Maildir
    chown -R alias /var/qmail/alias/Maildir
  EOC
  creates "~alias/Maildir"
end

# bash 'start qmail' do
#   user 'root'
#   group 'root'
#   code <<-EOC
#     sudo /usr/local/bin/qmail start
#   EOC
# end


