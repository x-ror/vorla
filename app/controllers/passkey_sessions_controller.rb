class PasskeySessionsController < ApplicationController
  allow_unauthenticated_access

  # POST /passkeys/authenticate/options
  def options
    get_options = WebAuthn::Credential.options_for_get(
      allow: PasskeyCredential.pluck(:external_id)
    )

    session[:webauthn_authentication_challenge] = get_options.challenge

    render json: get_options
  end

  # POST /passkeys/authenticate/verify
  def verify
    credential_json = JSON.parse(request.body.read)
    webauthn_credential = WebAuthn::Credential.from_get(credential_json)

    stored_credential = PasskeyCredential.find_by!(external_id: webauthn_credential.id)

    webauthn_credential.verify(
      session.delete(:webauthn_authentication_challenge),
      public_key: stored_credential.public_key,
      sign_count: stored_credential.sign_count
    )

    stored_credential.update!(sign_count: webauthn_credential.sign_count)

    start_new_session_for(stored_credential.user)
    render json: { redirect_to: after_authentication_url }
  rescue WebAuthn::Error, ActiveRecord::RecordNotFound => e
    render json: { error: "Authentication failed. Please try again." }, status: :unprocessable_entity
  end
end
