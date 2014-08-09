# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, 'redmine_sber'
set :deploy_to,     "/var/www/#{fetch(:application)}/plugins/issue_defaults"
set :repo_url, 'git@github.com:k41n/issue_default.git'
set :rvm_ruby_string, '2.1.2@redmine-2.5'
set :rvm_type, :system
set :user, 'root'
set :use_sudo, false

set :db_host, '127.0.0.1'
set :db_name, 'pda_production'
set :db_user, 'railrunner'
set :db_pass, 'hul5OP6DaK6a'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5
  
namespace :deploy do

  desc <<-DESC
    Start the application servers.
  DESC
  task :start do
    on roles(:app) do
      prefix = "source ~#{user}/.rvm/scripts/rvm; cd #{current_path}; rvm #{rvm_ruby_string} do eye "
      run "#{prefix} quit"
      run "#{prefix} load config/eye"
      run "#{prefix} start #{application}"
    end
  end

  desc <<-DESC
    Restart the application servers.
  DESC
  task :restart do
    on roles(:app) do
      prefix = "cd #{fetch(:deploy_to)}; rvm #{fetch(:rvm_ruby_string)} do eye "
      execute "#{prefix} stop #{fetch(:application)}; echo 'Stopped anyway'"
      execute "#{prefix} unmonitor #{fetch(:application)}; echo 'Unmonitored anyway'"
      execute "#{prefix} quit; echo 'Quit anyway'"
      execute "#{prefix} load config/eye"
      execute "#{prefix} info"
      execute "#{prefix} start #{fetch(:application)}"
    end
  end

  desc <<-DESC
    Stop the application servers.
  DESC
  task :stop do
    on roles(:app) do
      prefix = "source ~#{fetch(:user)}/.rvm/scripts/rvm; cd #{current_path}; rvm #{fetch(:rvm_ruby_string)} do eye "
      run "#{prefix} stop #{application}"
      run "#{prefix} quit"
    end
  end

  task :info do
    on roles(:app) do
      prefix = "source ~#{fetch(:user)}/.rvm/scripts/rvm; cd #{current_path}; rvm #{fetch(:rvm_ruby_string)} do eye "
      run "#{prefix} info #{application}"
    end
  end

  desc 'Loads database dump from staging'
  task :pull_db do
    `rm -f sber.sql`
    prefix = "source ~#{user}/.rvm/scripts/rvm; cd #{current_path}; rvm #{rvm_ruby_string} do eye "
    run "#{prefix} stop #{application}"

    run "mysqldump -u #{db_user} #{db_name} | bzip2 > /tmp/sber.sql.bz2"
    get '/tmp/sber.sql.bz2', 'sber.sql.bz2'
    `bunzip2 sber.sql.bz2`
    File.open 'config/database.yml' do |file|
      yaml = YAML.load(file.read)
      dc = yaml['development']
      dc ||= yaml['production']
      `dropdb #{dc['database']}`
      `createdb #{dc['database']}`
      `mysql -u #{dc['username']} #{dc['database']} < sber.sql`
      `rm -f sber.sql`
    end

    prefix = "source ~#{fetch(:user)}/.rvm/scripts/rvm; cd #{current_path}; rvm #{rvm_ruby_string} do eye "
    run "#{prefix} start #{application}"

  end

  desc 'Synchronize images to staging'
  task :pull_images do
    `rsync -rL #{user}@$CAPISTRANO:HOST$:#{release_path}/public/system public/`
  end

  desc 'Bundle install'
  task :bundle do
    on roles(:app) do
      prefix = "cd #{fetch(:deploy_to)}; rvm #{fetch(:rvm_ruby_string)} do "
      execute "#{prefix} bundle install"
    end
  end
  after :updated, :bundle

  task :copy_eye_config do
    on roles(:app) do
      execute "cp #{fetch(:deploy_to)}/config/eye/sber.eye.#{fetch(:stage)} #{fetch(:deploy_to)}/config/eye/sber.eye"
    end
  end  
  after :updated, :copy_eye_config

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within release_path do
        execute :rake, 'cache:clear'
      end
    end
  end

  task :updating do
    on roles(:app) do
      prefix = "cd #{fetch(:deploy_to)};"
      execute "#{prefix} git pull origin master"
    end
  end
end