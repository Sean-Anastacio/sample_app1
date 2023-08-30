class ApplicationMailer < ActionMailer::Base
  default from: "user@realdomain.com" #本番環境では自分が使っているメールアドレスにする
  layout "mailer"
end
