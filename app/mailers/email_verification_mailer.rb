class EmailVerificationMailer < ApplicationMailer
  def verify(user)
    @user = user
    mail subject: t("mailers.email_verification.verify.subject"), to: user.email_address
  end
end
