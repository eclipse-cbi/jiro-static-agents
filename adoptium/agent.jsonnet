local newDeployment(projectName, agentName) = {
  project: {
    fullName: projectName,
    shortName: std.split(self.fullName, ".")[std.length(std.split(self.fullName, "."))-1],
    workDir: "/var/jenkins",
  },
  secretTokenName: "inbound-agent-token",
  secretMountPath: "/var/run/secrets/jenkins/agent",
  kube: {
    namespace: $.project.shortName,
    servicePortName: "http",
    local labels(name) = {
      "org.eclipse.cbi.jiro.external-agent/project.fullName": name,
    },
    local metadata(name) = {
      name: name,
      namespace: $.kube.namespace,
      labels: labels(name),
      annotations: {
        "org.eclipse.cbi.jiro.external-agent/agent.name": agentName,
      },
    },
    metadata:: metadata,
    resources: [
      {
        kind: "Namespace",
        apiVersion: "v1",
        metadata: {
          name: $.kube.namespace,
          labels: {
            "org.eclipse.cbi.jiro/project.fullName": $.project.fullName,
            "org.eclipse.cbi.jiro/project.shortname": $.project.shortName,
          }
        },
      },
      {
        apiVersion: "apps/v1",
        kind: "Deployment",
        metadata: metadata($.project.fullName) {
          name: agentName,
        },
        spec: {
          selector: {
            matchLabels: labels($.project.fullName),
          },
          replicas: 1,
          template: {
            metadata: {
              labels: labels($.project.fullName),
              annotations: {
                "org.eclipse.cbi.jiro.external-agent/agent.name": agentName,
              },
            },
            spec: {
              affinity: {
                nodeAffinity: {
                  preferredDuringSchedulingIgnoredDuringExecution: [{
                    preference: {
                      matchExpressions: [{
                        key: "speed",
                        operator: "NotIn",
                        values: ["fast",]
                      }]
                    },
                    weight: 1
                  }]
                },
              },
              containers: [
                {
                  name: "agent",
                  image: "eclipsecbi/jiro-agent-basic-ubuntu:remoting-3261.v9c670a_4748a_9",
                  imagePullPolicy: "Always",
                  resources: {
                    limits: {
                      cpu: 2,
                      memory: "2Gi",
                    },
                    requests: {
                      cpu: 2,
                      memory: "2Gi",
                    },
                  },
                  command: ["/usr/bin/dumb-init", "--", "/bin/bash", "-c"],
                  args: [ |||
                      exec java -Xmx512m -jar /usr/share/jenkins/agent.jar \
                      -jnlpUrl https://ci.adoptium.net/computer/eclipse-codesign-machine/slave-agent.jnlp \
                      -secret @"%s/%s" \
                      -workDir "%s"
                    ||| % [$.secretMountPath, $.secretTokenName, $.project.workDir]
                  ],
                  volumeMounts: [
                    {
                      mountPath: $.project.workDir,
                      name: "workdir",
                    }, {
                      mountPath: "/home/jenkins/",
                      name: "jenkinshome"
                    }, {
                      mountPath: $.secretMountPath,
                      name: "agent-secret"
                    }, {
                      mountPath: "/tmp",
                      name: "tmp",
                    }
                  ],
                }
              ],
              volumes: [
                {
                  emptyDir: {},
                  name: "tmp"
                },
                {
                  emptyDir: {},
                  name: "jenkinshome",
                },
                {
                  emptyDir: {},
                  name: "workdir"
                },
                {
                  secret: {
                    secretName: "%s-secret" % agentName
                  },
                  name: "agent-secret"
                },
              ]
            }
          }
        }
      },
    ],
  },
  "kube.yml": std.manifestYamlStream($.kube.resources, true, c_document_end=false),
};
{
  newDeployment:: newDeployment,
}
