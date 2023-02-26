require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  ##
  # test all routes which lead to this controller
  def test_routes
    assert_routing(
      { :path => "/profile/edit", :method => :get },
      { :controller => "profiles", :action => "edit" }
    )

    assert_routing(
      { :path => "/profile", :method => :put },
      { :controller => "profiles", :action => "update" }
    )
  end

  def test_update
    user = create(:user)
    session_for(user)

    # Updating the description should work
    put profile_path, :params => { :user => { :description => "new description" } }
    assert_response :redirect
    assert_redirected_to user_path(user)
    follow_redirect!
    assert_response :success
    assert_template :show
    assert_select ".notice", /^Profile updated./
    assert_select "div", "new description"

    # Changing to an uploaded image should work
    image = Rack::Test::UploadedFile.new("test/gpx/fixtures/a.gif", "image/gif")
    put profile_path, :params => { :avatar_action => "new", :user => { :avatar => image, :description => user.description } }
    assert_response :redirect
    assert_redirected_to user_path(user)
    follow_redirect!
    assert_response :success
    assert_template :show
    assert_select ".notice", /^Profile updated./
    get edit_profile_path
    assert_select "form > fieldset > div > div.col-sm-10 > div.form-check > input[name=avatar_action][checked][value=?]", "keep"

    # Changing to a gravatar image should work
    put profile_path, :params => { :avatar_action => "gravatar", :user => { :description => user.description } }
    assert_response :redirect
    assert_redirected_to user_path(user)
    follow_redirect!
    assert_response :success
    assert_template :show
    assert_select ".notice", /^Profile updated./
    get edit_profile_path
    assert_select "form > fieldset > div > div.col-sm-10 > div > div.form-check > input[name=avatar_action][checked][value=?]", "gravatar"

    # Removing the image should work
    put profile_path, :params => { :avatar_action => "delete", :user => { :description => user.description } }
    assert_response :redirect
    assert_redirected_to user_path(user)
    follow_redirect!
    assert_response :success
    assert_template :show
    assert_select ".notice", /^Profile updated./
    get edit_profile_path
    assert_select "form > fieldset > div > div.col-sm-10 > div > input[name=avatar_action][checked]", false
    assert_select "form > fieldset > div > div.col-sm-10 > div > div.form-check > input[name=avatar_action][checked]", false
  end

  def test_og_tags
    user = create(:user, :display_name => "user display name")
    # TODO: remove raw URL path and use some function?
    get "/user/user%20display%20name"
    assert_response :success
    assert_select "head meta[property='og:type'][content='person']"
    #assert_select "head meta[property='og:locale'][content='en']"
    assert_select "head meta[property='og:title'][content='user display name | OpenStreetMap']"
    assert_select "head meta[property='og:image']"
    # Error: undefined local variable or method `helpers'
    #assert_select "head meta[property='og:image'][content='#{helpers.user_image_url(@user)}']"
    assert_select "head meta[property='og:image:secure_url']"
    assert_select "head meta[property='og:image:alt'][content='Profile image of user display name on OpenStreetMap.org']"
  end

end
