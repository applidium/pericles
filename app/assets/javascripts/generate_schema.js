function get_resource_representation_url(resource_id, resource_representation_id) {
  return '/resources/' + resource_id + '/resource_representations/' + resource_representation_id + '.json_schema';
}

function generate_schema_from_resource_representation(clicked_button) {
  var select_element = $(clicked_button).siblings(".form-group").find("select");
  var resource_representation_id = select_element.val();
  if (resource_representation_id) {
    var resource_id = $(clicked_button).attr('resource_id');
    var url = get_resource_representation_url(resource_id, resource_representation_id);
    var params = '?is_collection=' + $(clicked_button).siblings('.checkbox').find('input[type=checkbox]')[0].checked;
    var root_key = $(clicked_button).siblings('.form-group').children('input.root-key').val();
    if (root_key)
      params += '&root_key=' + root_key;
    var body_json_schema = $(clicked_button).siblings(".form-group").children("textarea");
    $.ajax({
        type: "GET",
        url: url + params,
        dataType: 'json'
      })
      .done(function(data) {
        body_json_schema.val(JSON.stringify(data, null, 2));
      });
  }
}

$(document).ready(function() {
  $("#route_request_resource_representation_id, #route_request_is_collection, #route_request_root_key, " +
    "#response_resource_representation_id, #response_is_collection, #response_root_key" +
    "#response_api_error_id"
  ).change(function() {
    generate_schema_from_resource_representation($( "#generate-schema" ))
  });
});