require 'test_helper'

class AttributesResourceRepresentationTest < ActiveSupport::TestCase
  test "A resource_representation shouldn't be associated with the same attribute twice" do
    resource_representation = create(:resource_representation)
    attribute = create(:attribute, parent_resource: resource_representation.resource)
    create(:attributes_resource_representation, resource_attribute: attribute,
     parent_resource_representation: resource_representation)
    assert_not build(:attributes_resource_representation, resource_attribute: attribute,
     parent_resource_representation: resource_representation).valid?
  end

  test "An attributes_resource_representation with an attribute that has a resource type must have an associated
   resource_representation to represent the resource referenced by the attribute" do
    resource_representation = create(:resource_representation)
    attribute_with_resource = create(:attribute_with_resource, parent_resource: resource_representation.resource)
    assert_not build(:attributes_resource_representation, resource_attribute: attribute_with_resource,
      parent_resource_representation: resource_representation).valid?
  end
end
