require 'test_helper'

class SessionControllerTest < ActionController::TestCase
  setup do
    @user = users(:john)
    @email_credential = credentials(:john_email)
    @password_credential = credentials(:john_password)
    @token_credential = credentials(:john_email_token)
  end

  test "user home page" do
    set_session_current_user @user
    get :show

    assert_equal @user, assigns(:user)
    assert_select 'a', '6.006'
  end


  ## TODO this login code does not work
  #test "user login works and purges old sessions" do
  #  old_token = credentials(:jane_session_token)
  #  old_token.updated_at = Time.now - 1.year
  #  old_token.save!
  #  post :create, :email => @email_credential.email, :password => 'password'
  #  assert_equal @user, session_current_user, 'session'
  #  assert_redirected_to session_url
  #  assert_nil Credentials::Token.with_code(old_token.code),
  #             'old session not purged'
  #end

  test "user logged in JSON request" do
    set_session_current_user @user
    get :show, :format => 'json'

    assert_equal @user.exuid,
        ActiveSupport::JSON.decode(response.body)['user']['exuid']
  end

  test "application welcome page" do
    get :show
    ## TODO why was this line present??
    # assert_equal User.count, assigns(:user_count)
    assert_select 'a', "6.006\n              Introduction to Algorithms"
  end

  ## TODO no path
  #test "user not logged in with JSON request" do
  #  get :show, :format => 'json'
  #
  #  assert_equal({}, ActiveSupport::JSON.decode(response.body))
  #end

  test "user login page" do
    get :new
    assert_template :new

    assert_select 'form[action=?]', session_path do
      assert_select 'input[name="email"]'
      assert_select 'input[name="password"]'
      assert_select 'button[name="login"]'
      assert_select 'button[name="reset_password"]'
    end
  end

  test "e-mail verification link" do
    get :token, :code => @token_credential.code
    assert_redirected_to session_url
    assert @email_credential.reload.verified?, 'Email not verified'
  end

  #TODO ActiveRecord::SubclassNotFound: The single-table inheritance mechanism failed to locate the subclass: 'Tokens::Base'. This error is raised because the column 'type' is reserved for storing the class in case of inheritance. Please rename this column if you didn't intend it to be used for storing the inheritance class or overwrite Credential.inheritance_column to use another column for that information.

  #test "password reset link" do
  #  password_credential = credentials(:jane_password)
  #  get :token, :code => credentials(:jane_password_token).code
  #  assert_redirected_to change_password_session_url
  #  assert_nil Credential.where(:id => password_credential.id).first,
  #             'Password not cleared'
  #end

  test "password change form" do
    set_session_current_user @user
    get :password_change

    assert_select 'form[action=?][method="post"]',
                  change_password_session_path do
      assert_select 'input[name="old_password"]'
      assert_select 'input[name=?]', 'credential[password]'
      assert_select 'input[name=?]', 'credential[password_confirmation]'
      assert_select 'input[type=submit]'
    end
  end

  test "password reset form" do
    set_session_current_user @user
    @password_credential.destroy
    get :password_change

    assert_select 'form[action=?][method="post"]',
                  change_password_session_path do
      assert_select 'input[name="old_password"]', :count => 0
      assert_select 'input[name=?]', 'credential[password]'
      assert_select 'input[name=?]', 'credential[password_confirmation]'
      assert_select 'input[type=submit]'
    end
  end

  test "password reset request" do
    ActionMailer::Base.deliveries = []

    assert_difference 'Credential.count', 1 do
      post :reset_password, :email => @email_credential.email
    end

    assert !ActionMailer::Base.deliveries.empty?, 'email generated'
    email = ActionMailer::Base.deliveries.last
    assert_equal [@email_credential.email], email.to

    assert_redirected_to new_session_url
  end
end
