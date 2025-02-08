package otel_test

import data.otel
import rego.v1

expected_template_block_patch := {
	"op": "add",
	"path": "/TaskGroups/0/Tasks/0/Templates/-",
	"value": {
		"EmbeddedTmpl": sprintf("%s=%s", ["OTEL_RESOURCE_ATTRIBUTES", concat(
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
				"nomad.job.type=service",
				"nomad.namespace={{ env \"NOMAD_NAMESPACE\" }}",
				"nomad.task.name={{ env \"NOMAD_TASK_NAME\" }}",
				"nomad.task.driver=docker",
			],
		)]),
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

exptected_artifact_patch := {
	"op": "add",
	"path": "/TaskGroups/0/Tasks/0/Artifacts/-",
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

exptected_java_agent_env_patch := {
	"op": "add",
	"path": "/TaskGroups/0/Tasks/0/Env/JAVA_TOOL_OPTIONS",
	"value": "-javaagent:/local/opentelemetry-javaagent.jar",
}

test_otel_patch if {
	input_job := {
		"ID": "my-job",
		"Name": "my-job",
		"Type": "service",
		"TaskGroups": [{
			"Name": "my-group",
			"Tasks": [{
				"Driver": "docker",
				"Name": "my-task",
				"Artifacts": [],
				"Env": {},
				"Templates": [],
			}],
		}],
	}
	patch_ops := otel.patch with input as input_job

	patch_ops == [exptected_artifact_patch, exptected_java_agent_env_patch, expected_template_block_patch]
}

test_otel_patch_default_to_type_service if {
	input_job := {
		"ID": "my-job",
		"Name": "my-job",
		"TaskGroups": [{
			"Name": "my-group",
			"Tasks": [{
				"Driver": "docker",
				"Meta": {"otel": "true"},
				"Name": "my-task",
				"Artifacts": [],
				"Env": {},
				"Templates": [],
			}],
		}],
	}
	patch_ops := otel.patch with input as input_job

	patch_ops == [exptected_artifact_patch, exptected_java_agent_env_patch, expected_template_block_patch]
}

test_otel_patch_full if {
	input_job := {
		"ID": "my-job",
		"Name": "my-job",
		"Type": "service",
		"TaskGroups": [{
			"Name": "my-group",
			"Tasks": [{
				"Driver": "docker",
				"Meta": null,
				"Name": "my-task",
			}],
		}],
	}
	patch_ops := otel.patch with input as input_job


	patch_ops == [
		{
			"op": "add",
			"path": "/TaskGroups/0/Tasks/0/Artifacts",
			"value": [],
		},
		exptected_artifact_patch,
		{
			"op": "add",
			"path": "/TaskGroups/0/Tasks/0/Env",
			"value": {},
		},
		exptected_java_agent_env_patch,
		{
			"op": "add",
			"path": "/TaskGroups/0/Tasks/0/Templates",
			"value": [],
		},
		expected_template_block_patch,
	]
}
