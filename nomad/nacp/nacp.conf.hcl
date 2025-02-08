mutator "opa_json_patch" "inject_otel" {

  opa_rule {
    query    = "patch = data.otel.patch"
    filename = "/local/otel.rego"
  }

}
