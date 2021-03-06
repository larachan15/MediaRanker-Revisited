require 'pry'
require 'test_helper'

describe WorksController do
  let (:work_data) {
    {
      work: {
        title: "new test book",
        category: "book"
      }
    }
  }

  let (:existing_work) {
    works(:movie)
  }

  let (:destroy_all_work) {
    Work.all.each do |work|
      work.destroy
    end
  }

  describe 'guest user' do
    describe "root" do
      it "succeeds with all media types" do
        # Precondition: there is at least one media of each category
        get root_path

        must_respond_with :success
      end

      it "succeeds with one media type absent" do
        # Precondition: there is at least one media in two of the categories
        get work_path(:existing_work)
        # must_respond_with :success

        existing_work.destroy
        get root_path
        must_respond_with :success
      end

      it "succeeds with no media" do
        destroy_all_work

        get root_path

        must_respond_with :success
      end
    end

    it 'cannot access show' do
      get work_path(Work.last.id)
      must_respond_with :redirect
      expect(flash[:result_text]).must_equal "You do not have access to this page. Please log in."
    end

    it 'cannot access new' do
      get new_work_path
      must_respond_with :redirect
      expect(flash[:result_text]).must_equal "You do not have access to this page. Please log in."
    end

    it 'cannot access create' do
      post works_path
      must_respond_with :redirect
      expect(flash[:result_text]).must_equal "You do not have access to this page. Please log in."
    end

    it 'cannot acccess edit' do
      get edit_work_path(Work.last.id)
      must_respond_with :redirect
      expect(flash[:result_text]).must_equal "You do not have access to this page. Please log in."
    end

    it 'cannot access update' do
      patch work_path(Work.last.id)
      must_respond_with :redirect
      expect(flash[:result_text]).must_equal "You do not have access to this page. Please log in."

    end

    it 'cannot access destroy' do
      delete work_path(Work.last.id)
      must_respond_with :redirect
      expect(flash[:result_text]).must_equal "You do not have access to this page. Please log in."
    end

    it 'cannot access upvote' do
      post upvote_path(works(:album).id), params: {
        vote: { user: users(:dionisia), work: works(:album).id }
      }
      must_respond_with :redirect
      must_redirect_to root_path
      expect(flash[:status]).must_equal :failure
    end

  end


  CATEGORIES = %w(albums books movies)
  INVALID_CATEGORIES = ["nope", "42", "", "  ", "albumstrailingtext"]
  # LOGGED IN USERS!
  describe "index" do
    before do
      login_test(users(:nick))
    end

    it "succeeds when there are works" do
      get works_path

      must_respond_with :success
    end

    it "succeeds when there are no works" do
      destroy_all_work

      get works_path

      must_respond_with :success
    end
  end

  describe "new" do
    it "succeeds" do
      login_test(users(:nick))
      get new_work_path

      must_respond_with :success
    end
  end

  describe "create" do
    before do
      login_test(users(:nick))
    end

    it "creates a work with valid data for a real category" do
      # Arrange
      # Assumption
      # Act
      # Assert

      CATEGORIES.each do |category|
        work_data[:work][:category] = category

        test_work = Work.new(work_data[:work])
        test_work.must_be :valid?, "Work data was invalid. Please come fix this test"

        expect {
          post works_path, params: work_data
          # binding.pry
        }.must_change('Work.count', +1)

        must_redirect_to work_path(Work.last)
      end
    end
    #
    it "renders bad_request and does not update the DB for bogus data" do
      INVALID_CATEGORIES.each do |invalid|
        work_data[:work][:category] = invalid
        # binding.pry
        invalid_work = Work.new(work_data[:work])
        invalid_work.wont_be :valid?, "Work was invalid. Please come fix this test"

        # binding.pry
        expect {
          post works_path, params: work_data
          # binding.pry
        }.wont_change('Work.count')

        # Assert
        must_respond_with :bad_request
      end
    end

    it "renders 400 bad_request for bogus categories" do
      INVALID_CATEGORIES.each do |invalid|
        work_data[:work][:category] = invalid
        invalid_work = Work.new(work_data[:work])
        invalid_work.wont_be :valid?, "Work was invalid. Please come fix this test"

        # Act
        expect {
          post works_path, params: work_data
        }.wont_change('Work.count')

        # Assert
        must_respond_with :bad_request
      end
    end
  end
  #
  describe "show" do
    before do
      login_test(users(:nick))
    end

    it "succeeds for an extant work ID" do
      get work_path(existing_work.id)

      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      existing_work.destroy

      get work_path(existing_work)

      must_respond_with :not_found
    end
  end
  #
  describe "edit" do
    before do
      login_test(users(:nick))
    end

    it "succeeds for an extant work ID" do
      get edit_work_path(existing_work)
      must_respond_with :success
    end

    it "renders 404 not_found for a bogus work ID" do
      existing_work.destroy
      get edit_work_path(existing_work)
      must_respond_with :not_found
    end
  end
  #
  describe "update" do
    before do
      login_test(users(:nick))
    end

    it "succeeds for valid data and an extant work ID" do
      id = works(:poodr).id
      expect {
        patch work_path(id), params: work_data
      }.wont_change 'Work.count'

      must_respond_with :redirect

      work = Work.find_by(id: id)
      expect(work.title).must_equal work_data[:work][:title]
      expect(work.category).must_equal work_data[:work][:category]

    end

    it "renders bad_request for bogus data" do
      id = works(:poodr).id
      original_work = works(:poodr)
      work_data[:work][:title] = nil
      work_data[:work][:category] = 'stuffstuffstuff'
      expect {
        patch work_path(id), params: work_data
      }.wont_change 'Work.count'

      must_respond_with :bad_request

      work = Work.find_by(id: id)
      expect(work.title).must_equal original_work.title
      expect(work.category).must_equal original_work.category
    end

    it "renders 404 not_found for a bogus work ID" do
      id = 'i am so happy'

      expect {
        patch work_path(id), params: work_data
      }.wont_change 'Work.count'

      must_respond_with :not_found
    end
  end
  #
  describe "destroy" do
    before do
      login_test(users(:nick))
    end

    it "succeeds for an extant work ID" do
      expect {
        delete work_path(existing_work)
      }.must_change('Work.count', -1)

      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "renders 404 not_found and does not update the DB for a bogus work ID" do
      existing_work.destroy

      expect {
        delete work_path(existing_work.id)
      }.wont_change('Work.count')

      must_respond_with :not_found
    end
  end
  #
  describe "upvote" do
    before do
      login_test(users(:nick))
    end

    it "redirects to the work page if no user is logged in" do
      delete logout_path, params: { username: users(:nick).username }

      post upvote_path(existing_work.id), params: {
        vote: { user: users(:nick), work: works(:album).id }
      }
      must_respond_with :redirect
      must_redirect_to root_path
    end

    it "redirects to the work page after the user has logged out" do
      user = users(:nick)
      OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(mock_auth_hash(user))
      get auth_callback_path(:github)
      expect ( session[:user_id] ).must_equal users(:nick).id

      delete logout_path

      must_respond_with :redirect
      must_redirect_to root_path
      expect(flash[:success]).must_equal "Successfully logged out!"
      session[:user_id].must_be_nil
    end

    it "succeeds for a logged-in user and a fresh user-vote pair" do
      post upvote_path(existing_work.id), params: {
        vote: { user: users(:dionisia), work: existing_work }
      }
      must_respond_with :redirect
    end

    it "redirects to the work page if the user has already voted for that work" do
      2.times do
        post upvote_path(existing_work.id), params: {
          vote: { user: users(:nick), work: existing_work }
        }
      end

      must_redirect_to work_path(existing_work)
      must_respond_with :redirect
    end
  end
end
