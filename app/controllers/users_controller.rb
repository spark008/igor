class UsersController < ApplicationController
  before_filter :authenticated_as_admin, :except =>
      [:new, :create, :show, :check_email]
  before_filter :authenticated_as_user, :only => [:update, :show]
   
  # GET /users
  def index
    @users = User.includes([:credentials, :profile]).all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /users/1
  def show
    @user = User.find_by_param params[:id]

    respond_to do |format|
      format.html # show.html.erb
    end
  end
  
  # GET /users/new
  def new
    @user = User.new
    @user.build_profile
    registration = @user.registrations.build
    registration.course = Course.main
    registration.build_prerequisite_answers

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find_by_param params[:id]
  end

  # POST /users
  def create
    @user = User.new params[:user]
    # The first user becomes an administrator by default.
    @user.admin = (User.count == 0)
    if registration = @user.registrations.first
      registration.course = Course.main
    end

    respond_to do |format|
      if @user.save
        token = Tokens::EmailVerification.random_for @user.email_credential
        SessionMailer.email_verification_email(token, root_url).deliver
        
        format.html do
          redirect_to new_session_url,
              :alert => 'Please check your e-mail to verify your account.'
        end
      else
        format.html { render :action => :new }
      end
    end
  end
  
  # PUT /users/1
  def update
    @user = User.find_by_param params[:id]
    return bounce_user unless @user.can_edit?(current_user)

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User information successfully updated.'
        format.html { redirect_to(@user) }
      else
        format.html { render :action => :edit }
      end
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find_by_param params[:id]
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
    end
  end    

  # XHR /users/check_email?email=...
  def check_email
    @email = params[:user][:email]
    @user = User.with_email @email
    
    render :layout => false
  end

  # XHR /users/lookup?query=...
  def lookup    
    @query = params[:query]
    @users = User.find_all_by_query!(@query)
    
    respond_to do |format|
      format.js { render :layout => false } # lookup.js.erb
      format.html # nothing so far
    end
  end
  
  # POST /users/1/set_admin?to=true
  def set_admin
    @user = User.find_by_param params[:id]
    @user.admin = params[:to] || false
    @user.save!
    
    if @user.admin
      flash[:notice] = "#{@user.name} has been granted staff privileges."
    else
      flash[:notice] = "#{@user.name} no longer has staff privileges."
    end
    redirect_to users_url
  end

  # PUT /users/1/confirm_email
  def confirm_email
    @user = User.find_by_param params[:id]
    @user.email_credential.verified = true
    @user.email_credential.save!
    
    flash[:notice] = "#{@user.name}'s email has been manually confirmed."
    redirect_to users_url
  end
    
    # POST /users/1/impersonate
  def impersonate
    @user = User.find_by_param params[:id]
    return bounce_user('Cannot impersonate another admin.') if @user.admin?
    
    self.current_user = @user
    respond_to do |format|
      format.html { redirect_to root_path }
    end
  end
end
