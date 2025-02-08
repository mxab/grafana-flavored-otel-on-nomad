package otel

import rego.v1

add_artifacts_field_ops contains op if {
	some g, t

	object.get(input.TaskGroups[g].Tasks[t], "Artifacts", null) == null

	op := {
		"op": "add",
		"path": sprintf("/TaskGroups/%d/Tasks/%d/Artifacts", [g, t]),
		"value": [],
	}
}

add_otel_agent_artifact_ops contains op if {
	some g, t
	input.TaskGroups[g].Tasks[t]
	op := {
		"op": "add",
		"path": sprintf("/TaskGroups/%d/Tasks/%d/Artifacts/-", [g, t]),
		"value": {
			"GetterSource": "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v2.12.0/opentelemetry-javaagent.jar",
			"GetterOptions": {"archive": "false"},
			"GetterHeaders": null,
			"GetterMode": "any",
			"GetterInsecure": false,
			"RelativeDest": "local/",
			"Chown": false,
		},
	}
}

add_env_field_ops contains op if {
	some g, t

	object.get(input.TaskGroups[g].Tasks[t], "Env", null) == null

	op := {
		"op": "add",
		"path": sprintf("/TaskGroups/%d/Tasks/%d/Env", [g, t]),
		"value": {},
	}
}

add_java_agent_env_ops contains op if {
	some g, t
	input.TaskGroups[g].Tasks[t]

	op := {
		"op": "add",
		"path": sprintf("/TaskGroups/%d/Tasks/%d/Env/JAVA_TOOL_OPTIONS", [g, t]),
		"value": "-javaagent:/local/opentelemetry-javaagent.jar",
	}
}

# if it doesn't have a Templates field or its null create a patch for that
# inject similar data as mentioned here: https://github.com/hashicorp/nomad/commit/fb4887505c82346a8f9046f956530058ab92e55a#diff-ad403bc14b99a07b6bf1d5599b9109113bc30d03afd88d7c007dd55f1bdb6b2cR44
add_templates_list_ops contains op if {
	some g, t

	object.get(input.TaskGroups[g].Tasks[t], "Templates", null) == null

	op := {
		"op": "add",
		"path": sprintf("/TaskGroups/%d/Tasks/%d/Templates", [g, t]),
		"value": [],
	}
}

# inject otel env

add_otel_env_template_ops contains op if {
	some g, t

	EmbeddedTmpl := sprintf("%s=%s", ["OTEL_RESOURCE_ATTRIBUTES", concat(
		",",
		[
			"service.name={{ env \"NOMAD_TASK_NAME\" }}",
			"service.instance.id={{ env \"NOMAD_SHORT_ALLOC_ID\" }}",
			"nomad.alloc.id={{ env \"NOMAD_ALLOC_ID\" }}",
			"nomad.alloc.name={{ env \"NOMAD_ALLOC_NAME\" }}",
			"nomad.alloc.index={{ env \"NOMAD_ALLOC_INDEX\" }}",
			"nomad.alloc.createTime={{ timestamp }}",
			"nomad.group.name={{ env \"NOMAD_GROUP_NAME\" }}",
			"nomad.job.id={{ env \"NOMAD_JOB_ID\" }}",
			"nomad.job.name={{ env \"NOMAD_JOB_NAME\" }}",
			"nomad.job.parentId={{ env \"NOMAD_JOB_PARENT_ID\" }}",
			sprintf("nomad.job.type=%s", [object.get(input, "Type", "service")]),
			"nomad.namespace={{ env \"NOMAD_NAMESPACE\" }}",
			"nomad.task.name={{ env \"NOMAD_TASK_NAME\" }}",
			sprintf("nomad.task.driver=%s", [input.TaskGroups[g].Tasks[t].Driver]),
		],
	)])
	op := {
		"op": "add",
		"path": sprintf("/TaskGroups/%d/Tasks/%d/Templates/-", [g, t]),
		"value": {
			"EmbeddedTmpl": EmbeddedTmpl,
			"DestPath": "local/otel.env",
			"ChangeMode": "restart",
			"ChangeScript": null,
			"ChangeSignal": "",
			"Envvars": true,
			"ErrMissingKey": false,
			"Gid": null,
			"LeftDelim": "{{",
			"Perms": "0644",
			"RightDelim": "}}",
			"SourcePath": "",
			"Splay": 5000000000,
			"Uid": null,
			"VaultGrace": 0,
			"Wait": null,
		},
	}
}

patch := [op |
	some ops in [
		add_artifacts_field_ops,
		add_otel_agent_artifact_ops,
		add_env_field_ops,
		add_java_agent_env_ops,
		add_templates_list_ops,
		add_otel_env_template_ops,
	]
	some op in ops
]
