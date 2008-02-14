require File.dirname(__FILE__) + '/../test_helper'
require 'tagz_controller'

# Re-raise errors caught by the controller.
class TagzController; def rescue_action(e) raise e end; end

class TagzControllerTest < Test::Unit::TestCase
  def setup
    @controller = TagzController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
