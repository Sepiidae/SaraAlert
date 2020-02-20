class AdminController < ApplicationController
  before_action :authenticate_user!

  def index
    if !current_user.has_role? :admin
      redirect_to root_url and return
    end
  end

  def create_user
    permitted_params = params[:admin].permit(:email, :jurisdiction, :role)
    roles = Role.pluck(:name)
    email = permitted_params[:email]
    raise "EMAIL must be provided" unless email
    password = SecureRandom.base58(10) # About 58 bits of entropy
    role = permitted_params[:role]
    raise "ROLE must be provided and one of #{roles}" unless role && roles.include?(role)
    jurisdictions = Jurisdiction.pluck(:id)
    jurisdiction = permitted_params[:jurisdiction]
    raise "JURISDICTION must be provided and one of #{jurisdictions}" unless jurisdiction && jurisdictions.include?(jurisdiction)
    user = User.create!(
      email: email,
      password: password,
      jurisdiction: Jurisdiction.find_by_id(jurisdiction),
      force_password_change: true # Require user to change password on first login
    )
    user.add_role role
    user.save!
    UserMailer.welcome_email(user, password).deliver_later
  end

end