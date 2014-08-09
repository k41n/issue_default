server "redmine-stas.kodep.ru", user: "root", roles: %w{web app db}

namespace :deploy do
  task :copy_eye_config do
    run "cp #{release_path}/config/eye/sber.eye.staging #{release_path}/config/eye/sber.eye"
  end
end