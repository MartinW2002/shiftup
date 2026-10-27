# Devise's destroy ignores whether the account was actually deleted. This version shows
# the reason instead when User refuses (for example while the user has upcoming shifts).
class Users::RegistrationsController < Devise::RegistrationsController
  def destroy
    if resource.destroy
      sign_out # all scopes, which is the Devise default
      set_flash_message! :notice, :destroyed
      redirect_to after_sign_out_path_for(resource_name), status: :see_other
    else
      redirect_to edit_user_registration_path, alert: resource.errors.full_messages.to_sentence, status: :see_other
    end
  end
end
