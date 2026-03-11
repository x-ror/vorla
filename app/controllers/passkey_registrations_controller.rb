class PasskeyRegistrationsController < ApplicationController
  # POST /passkeys/register/options
  def options
    ensure_webauthn_id!

    create_options = WebAuthn::Credential.options_for_create(
      user: {
        id: Current.user.webauthn_id,
        name: Current.user.email_address,
        display_name: Current.user.email_address.split("@").first
      },
      exclude: Current.user.passkey_credentials.pluck(:external_id)
    )

    session[:webauthn_creation_challenge] = create_options.challenge

    render json: create_options
  end

  # POST /passkeys/register/verify
  def verify
    credential_json = JSON.parse(request.body.read)
    webauthn_credential = WebAuthn::Credential.from_create(credential_json)

    webauthn_credential.verify(session.delete(:webauthn_creation_challenge))

    Current.user.passkey_credentials.create!(
      external_id: webauthn_credential.id,
      public_key: webauthn_credential.public_key,
      nickname: "Passkey",
      sign_count: webauthn_credential.sign_count
    )

    render json: { status: "ok" }
  rescue WebAuthn::Error => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /passkeys/:id
  def destroy
    credential = Current.user.passkey_credentials.find(params[:id])
    credential.destroy
    redirect_to active_sessions_path, notice: "Passkey removed."
  end

  private

  def ensure_webauthn_id!
    return if Current.user.webauthn_id.present?

    Current.user.update!(webauthn_id: WebAuthn.generate_user_id)
  end
end
