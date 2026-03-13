class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: t("mailers.passwords.reset.subject"), to: user.email_address
  end
end
