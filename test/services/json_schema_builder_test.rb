require 'test_helper'

class JSONSchemaBuilderTest < ActiveSupport::TestCase
  attr_accessor :attributes_resource_rep

  def generate_schema(is_collection, root_key, metadata_responses = [])
    self.attributes_resource_rep = build(:attributes_resource_representation)
    representation = build(:resource_representation,
      attributes_resource_representations: [attributes_resource_rep, build(:attributes_resource_representation)]
    )
    JSONSchemaBuilder.new(
      representation,
      is_collection: is_collection,
      root_key: root_key,
      metadata_responses: metadata_responses
    ).execute
  end

  def schema_with_one_attribute(key_name, primitive_type)
    attribute = build(:attribute, primitive_type: primitive_type)
    representation = build(:resource_representation,
      attributes_resource_representations: [
        build(:attributes_resource_representation, resource_attribute: attribute, custom_key_name: key_name)
      ]
    )
    JSONSchemaBuilder.new(
      representation,
      is_collection: false,
      root_key: nil
    ).execute
  end

  test 'should produce a valid json schema' do
    schema = generate_schema(false, 'root_key').to_json
    assert JSON::Validator.fully_validate(META_SCHEMA, schema, json: true).empty?, JSON::Validator.fully_validate(META_SCHEMA, schema, json: true)
  end

  test 'should be an array if is_collection is set and not root_key' do
    schema = generate_schema(true, '')
    assert_equal 'array', schema[:type]
    assert schema[:items]
  end

  test 'should be an object if no is_collection and no root_key' do
    schema = generate_schema(false, '')
    assert_equal 'object', schema[:type]
    assert schema[:properties]
  end

  test 'should be an object if is_collection and root_key' do
    schema = generate_schema(true, 'root_key')
    assert_equal 'object', schema[:type]
    assert schema[:properties]
  end

  test 'should be an object if no is_collection and root_key' do
    schema = generate_schema(false, 'root_key')
    assert_equal 'object', schema[:type]
    assert schema[:properties]
  end

  test 'should use root key' do
    assert generate_schema(false, 'root_key')[:properties][:root_key]
    assert generate_schema(true, 'root_key')[:properties][:root_key]
  end

  test 'root key object should be an array if root_key and is_collection' do
    schema = generate_schema(true, 'root_key')
    assert_equal 'array', schema[:properties][:root_key][:type]
    assert schema[:properties][:root_key][:items]
  end

  test 'root key object should be an object if root_key and no is_collection' do
    schema = generate_schema(false, 'root_key')
    assert_equal 'object', schema[:properties][:root_key][:type]
    assert schema[:properties][:root_key][:properties]
  end

  test 'should use required if root key' do
    assert_equal ['root_key'], generate_schema(true, 'root_key')[:required]
  end

  test 'should not use required if no root key and is_collection' do
    assert_not generate_schema(true, '')[:required]
  end

  test 'attribute name is in properties' do
    assert_includes generate_schema(false, '')[:properties], attributes_resource_rep.resource_attribute.default_key_name.to_sym
  end

  test 'attribute primitive type is set' do
    schema = generate_schema(false, '')
    attribute = attributes_resource_rep.resource_attribute
    assert_equal attribute.primitive_type, schema[:properties][attribute.default_key_name.to_sym][:type]
  end

  test 'attribute date type is string' do
    schema = schema_with_one_attribute('keyname', :date)
    assert_equal 'string', schema[:properties][:keyname][:type]
  end

  test 'attribute date format is date' do
    schema = schema_with_one_attribute('keyname', :date)
    assert_equal 'date', schema[:properties][:keyname][:format]
  end

  test 'attribute datetime type is string' do
    schema = schema_with_one_attribute('keyname', :datetime)
    assert_equal 'string', schema[:properties][:keyname][:type]
  end

  test 'attribute datetime format is datetime' do
    schema = schema_with_one_attribute('keyname', :datetime)
    assert_equal 'datetime', schema[:properties][:keyname][:format]
  end

  test 'attribute object is of type object' do
    schema = schema_with_one_attribute('keyname', :object)
    assert_equal({ type: 'object' }, schema[:properties][:keyname])
  end

  test 'attribute any is of all types' do
    schema = schema_with_one_attribute('keyname', :any)
    assert_equal({type: %w[string number integer boolean null array object] }, schema[:properties][:keyname])
  end

  test 'attribute resource representation is null' do
    attributes_resource_representation = build(:attributes_resource_representation, is_null: true)
    representation = build(:resource_representation,
      attributes_resource_representations: [attributes_resource_representation]
    )
    schema = JSONSchemaBuilder.new(
      representation,
      is_collection: false,
      root_key: ''
    ).execute
    assert_equal 'null', schema[:properties][attributes_resource_representation.resource_attribute.default_key_name.to_sym][:type]
  end

  test 'should include metadata' do
    metadatum = build(:metadatum, name: 'meta_name')
    metadata_response = build(:metadata_response, metadatum: metadatum)

    schema = generate_schema(false, 'root', [metadata_response])
    assert_not_nil schema[:properties][:meta_name]
    refute_includes schema[:required], :meta_name

    metadata_response = build(:metadata_response, metadatum: metadatum, required: true)
    schema = generate_schema(false, 'root', [metadata_response])
    assert_includes schema[:required], :meta_name
  end

  test 'should include metadata under key' do
    metadatum = build(:metadatum, name: 'meta_name')
    metadata_responses = [build(:metadata_response, metadatum: metadatum, key: 'meta_key', required: true)]

    schema = generate_schema(false, 'root', metadata_responses)
    assert_not_nil schema[:properties][:meta_key][:properties][:meta_name]
    assert_includes schema[:required], :meta_key
    assert_includes schema[:properties][:meta_key][:required], :meta_name
  end

  test 'should include several metadata under same key' do
    first_metadatum = build(:metadatum, name: 'first_meta_name')
    second_metadatum = build(:metadatum, name: 'second_meta_name')
    metadata_responses = [
      build(:metadata_response, metadatum: first_metadatum, key: 'meta_key', required: true),
      build(:metadata_response, metadatum: second_metadatum, key: 'meta_key', required: true)
    ]

    schema = generate_schema(false, 'root', metadata_responses)
    assert_not_nil schema[:properties][:meta_key][:properties][:first_meta_name]
    assert_not_nil schema[:properties][:meta_key][:properties][:second_meta_name]
    assert_equal ['root', :meta_key], schema[:required]
  end

  test 'schema with nested resources is correct' do
    resource = create(:resource, name: 'User')
    name_attribute = create(:attribute, parent_resource: resource, name: 'name', description: 'name of the user',
                                        primitive_type: :string
    )
    manager_attribute = create(:attribute, parent_resource: resource, name: 'manager', description: 'manager of the user',
                                           resource: resource, primitive_type: nil
    )
    resource_representation_user = create(:resource_representation, resource: resource, name: 'user', description: 'A user')
    resource_representation_manager = create(:resource_representation, resource: resource, name: 'manager')
    create(:attributes_resource_representation, parent_resource_representation: resource_representation_user,
                                                resource_attribute: name_attribute
    )
    create(:attributes_resource_representation, parent_resource_representation: resource_representation_user,
                                                resource_attribute: manager_attribute, resource_representation: resource_representation_manager
    )
    create(:attributes_resource_representation, parent_resource_representation: resource_representation_manager,
                                                resource_attribute: name_attribute
    )
    json_schema = {
      "title": 'User - user',
      "type": 'object',
      "definitions": {
        "manager_#{resource_representation_manager.id}": {
          "title": 'User - manager',
          "type": 'object',
          "properties": {
            "name": {
              "description": 'name of the user',
              "type": 'string'
            }
          },
          "additionalProperties": false
        }
      },
      "properties": {
        "user": {
          "type": 'object',
          "properties": {
            "name": {
              "description": 'name of the user',
              "type": 'string'
            },
            "manager": {
              "description": 'manager of the user',
              "type": 'object',
              "$ref": "#/definitions/manager_#{resource_representation_manager.id}"
            }
          },
          "additionalProperties": false
        }
      },
      "required": ['user'],
      "description": 'A user',
      "additionalProperties": false
    }

    json = JSONSchemaBuilder.new(
      resource_representation_user,
      is_collection: false,
      root_key: 'user'
    ).execute
    assert_equal JSON.stable_pretty_generate(json_schema), JSON.stable_pretty_generate(json), 'json schema is not correct'
  end
end
