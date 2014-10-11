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
set :db_name, 'redmine'
set :db_user, 'k41n'
set :db_pass, ENV['DB_PASS']

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
      prefix = "cd #{fetch(:deploy_to)}/../..; rvm #{fetch(:rvm_ruby_string)} do eye "
      execute "#{prefix} quit"
      execute "#{prefix} load config/eye"
      execute "#{prefix} start #{fetch(:application)}"
    end
  end

  desc <<-DESC
    Restart the application servers.
  DESC
  task :restart do
    on roles(:app) do
      prefix = "cd #{fetch(:deploy_to)}/../..; rvm #{fetch(:rvm_ruby_string)} do eye "
      execute "#{prefix} stop #{fetch(:application)}; echo 'Stopped anyway'"
      execute "#{prefix} unmonitor #{fetch(:application)}; echo 'Unmonitored anyway'"
      execute "#{prefix} quit; echo 'Quit anyway'"
      execute "#{prefix} load config/eye"
      execute "#{prefix} start #{fetch(:application)}"
      sleep 5
      execute "#{prefix} info"
    end
  end

  desc <<-DESC
    Stop the application servers.
  DESC
  task :stop do
    on roles(:app) do
      prefix = "cd #{fetch(:deploy_to)}/../..; rvm #{fetch(:rvm_ruby_string)} do eye "
      execute "#{prefix} stop #{fetch(:application)}"
      execute "#{prefix} quit"
    end
  end

  task :info do
    on roles(:app) do
      prefix = "cd #{fetch(:deploy_to)}/../..; rvm #{fetch(:rvm_ruby_string)} do eye "
      execute "#{prefix} info #{fetch(:application)}"
    end
  end

  desc 'Loads database dump from staging'
  task :pull_db do
    on roles(:db) do
      `rm -f sber.dump`
      prefix = "cd #{fetch(:deploy_to)}/../..; rvm #{fetch(:rvm_ruby_string)} do eye "
      execute "#{prefix} stop #{fetch(:application)}"

      execute "PGPASSWORD=\"#{fetch(:db_pass)}\" pg_dump -O -x -Fc -U #{fetch(:db_user)} #{fetch(:db_name)} -Z9 > /tmp/sber.dump"
      download! '/tmp/sber.dump', 'sber.dump'
      File.open '../../config/database.yml' do |file|
        yaml = YAML.load(file.read)
        dc = yaml['development']
        dc ||= yaml['production']
        `dropdb #{dc['database']}`
        `createdb #{dc['database']}`
        `pg_restore -O -d #{dc['database']} sber.dump`
        `rm -f sber.dump`
      end

      execute "#{prefix} start #{fetch(:application)}"
    end
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
      execute "cp #{fetch(:deploy_to)}/config/eye/sber.eye.#{fetch(:stage)} #{fetch(:deploy_to)}/../../config/eye/sber.eye"
    end
  end

  after :updated, :copy_eye_config

  task :db_migrate do
    on roles(:db) do
        prefix = "cd #{fetch(:deploy_to)}/../..; RAILS_ENV=#{fetch(:stage)} rvm #{fetch(:rvm_ruby_string)} do bundle exec "
        execute "#{prefix} rake redmine:plugins:migrate NAME=issue_defaults"

    end
  end
  after :updated, :db_migrate

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      within fetch(:deploy_to) do
        prefix = "cd #{fetch(:deploy_to)}/../..; RAILS_ENV=#{fetch(:stage)} rvm #{fetch(:rvm_ruby_string)} do bundle exec "
        execute "#{prefix} rake tmp:clear"
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