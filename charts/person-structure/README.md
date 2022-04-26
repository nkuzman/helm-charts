# Person structure application

## Purpose

This Helm chart installs Person structure application into your Kubernetes cluster.

Helm release name set during installation will be used for naming all resources created by this Helm chart.
For example, if Chart is installed with name "my-chart", deployment name will have "my-chart" prefix, as well as all configmaps, secrets and other resources created by this chart.
It is possible to override this behavior and to set custom name for resources using attribute `nameOverride` in custom values file.
If this attribute is set, it's value will be used to name all the resources, and release name will be ignored.

It is not possible to install application using default values only, there is a list of required attributes which should be applied when installing Person structure.

## Required setup

Required attributes should be defined in custom values file in `yaml` format (recommended) or propagated with `--set key=value` command during CLI installation, for example:

`helm upgrade --install person-structure vestigo/person-structure -f my-values.yaml` or

`helm upgrade --install person-structure vestigo/person-structure --set required-key1=value1 --set required-key2=value2 ...`

Required values are (in `yaml` format):

```yaml
secret:
  decryptionKey: "my-encryption-key" # string value
  datasourcePassword: "AES-encoded-datasource-password" # string value
  kafkaPassword: "AES-encoded-kafka-password" # string value
  kafkaSchemaRegistryPassword: "AES-encoded-kafka-schema-registry-password" # string value
  liquibasePassword: "Base-64-encoded-password-for-liquibase-user" # string value

datasource:
  host: "datasource-host" # string value
  port: 9999 # int value
  dbName: "database-name" # string value
  user: "database-user" # string value
  liquibaseUser: "liquibase-user" # string value
  schema: "database-schema" # string value

kafka:
  user: "kafka-user" # string value
  servers: "kafka-server:port" # string value
  schemaRegistry:
    user: "kafka-schema-registry-user" # string value
    url: "kafka-schema-registry-url" # string value

imagePullSecrets:
  - name: "image-pull-secret-name" # string value
```

Person structure application relies on PostgreSQL database and Kafka backends.
In order to assure connectivity to those backends, it's required to set basic info into values file.

### Datasource connection setup

All values required for PostgreSQL database connection are defined within `datasource` parent attribute.
Application will not be able to connect to database if all attributes are not filled.

Required datasource attributes:

```yaml
datasource:
  host: "db-hostname" # only PostgreSQL hostname has to be defined (for instance "localhost")
  port: 5432 # PostgreSQL port number 
  dbName: "database-name" # Name of PostgreSQL database
  user: "database-user" # User which application will use to connect to PostgreSQL
  liquibaseUser: "liquibase-user" # User which Liquibase container will use to apply database changes
  schema: "database-schema" # PostgreSQL schema for Person structure application
```

In addition to datasource attributes, it's required to provide an AES encrypted password for database user specified in `datasource.user`, as well as base64 encoded user for Liquibase user defined in `datasource.liquibaseUser`.

Encryption key used to encrypt and decrypt datasource password (as well as Kafka passwords) is defined in `secret.decryptionKey` attribute.
Use this key to encrypt datasource password and define it in `secret.datasourcePassword`.

Password for Liquibase user (which will apply database changes for each version) has to be base64 encoded, and is not related to `secret.decryptionKey` attribute.

Datasource secret configuration:

```yaml
secret:
  decryptionKey: "my-encryption-key" # some custom encryption key
  datasourcePassword: "{AES}S0m3H4sh" # datasource password for user defined in datasource.user encrypted with custom encryption key
  liquibasePassword: "S0m3H4sh" # base64 encoded password for Liquibase user defined in datasource.liquibaseUser attribute
```

It's possible to additionally customize datasource connection by overriding following default attributes:

```yaml
datasource:
  connTimeout: 60000 # defines time (in ms) after which active connection will timeout and be closed
  maxPoolSize: 2 # defines max size of database connection pool
  minIdle: 0 # defines min number of retained idle connections
```

### Kafka setup

Person structure uses Kafka as event stream backend.
Other than Kafka cluster itself, Person structure application also uses Kafka Schema Registry, which setup also has to be provided in order to establish required connection.

To connect to Kafka cluster, several attributes have to be defined in values file.
All attributes under `kafka` parent attribute are required:

```yaml
kafka:
  user: "kafka-user" # user used to connect to Kafka cluster
  servers: "kafka-server1:port,kafka-server2:port" # a comma separated list of Kafka bootstrap servers
  schemaRegistry:
    user: "kafka-schema-registry-user" # user used to connect to Kafka Schema Registry
    url: "https://kafka.schema.registry.url" # URL for Kafka Schema Registry
```

As for database, passwords for Kafka cluster and Kafka Schema Registry are also AES encrypted.
Passwords should be defined with `secret.kafkaPassword` and `secret.kafkaSchemaRegistryPassword` attributes, for example:

```yaml
secret:
  decryptionKey: "my-encryption-key" # some custom encryption key
  kafkaPassword: "{AES}S0m3H4sh" # AES encrypted password for Kafka cluster user defined in kafka.user, encrypted with custom encryption key
  kafkaSchemaRegistryPassword: "{AES}S0m30th3rH4sh" # AES encrypted password for Kafka Schema Registry user defined in kafka.schemaRegistry.user, encrypted with custom encryption key
```

Note that same `secret` attribute is used for both datasource and Kafka, so the same encryption/decryption key is used for encrypting passwords for both backends.

Default Kafka cluster and Kafka Schema registry connection type used by Person structure is Basic auth (username and password).
If different connection type should be used, it's possible to override default setup by changing following attributes:

```yaml
kafka:
  saslMechanism: PLAIN # default value, set custom mechanism if required
  securityProtocol: SASL_SSL # default value, set custom protocol if required
```

#### Topics and consumer groups setup

Kafka topics and consumer group names used by Person structure have default names defined in `values.yaml` file, but can be overridden with following setup:

```yaml
kafka:
  topics:
    card:
      name: hr.vestigo.hp.card # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.card # default value, set custom name if required
    crdacc:
      name: hr.vestigo.hp.crdacc # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.crdacc # default value, set custom name if required
    custcrdintacc:
      name: hr.vestigo.hp.custcrdintacc # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.custcrdintacc # default value, set custom name if required
    customeraccount:
      name: hr.vestigo.hp.customeraccount # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.customeraccount # default value, set custom name if required
    authptragrmtlimalc:
      name: hr.vestigo.hp.authptragrmtlimalc # default value, set custom name if required
      consumerGroup: hr.vestigo.hp.authptragrmtlimalc # default value, set custom name if required
```

### Configuring image source and pull secrets

By default, Person structure image is pulled directly from Vestigo's registry on Docker Hub.
If mirror registry is used for example, image source can be modified using following attributes:

```yaml
image:
  repository: custom.url/custom-image-name
```

Default pull policy is set to `IfNotPresent` but can also be modified, for example:

```yaml
image:
  pullPolicy: Always
```

Image tag is normally read from Chart definition, but if required, it can be overridden with attribute `image.tag`, for example:

```yaml
image:
  tag: custom-tag
```

Since image is located on Vestigo's private Docker Hub registry, pull secret is mandatory.
Pull secret is not set by default, and it should be created prior to Person structure installation in target namespace.
Secret should contain credentials provided by Vestigo.

Once secret is created, it should be set with `imagePullSecrets.name` attribute, for example:

```yaml
imagePullSecrets:
  - name: vestigo-dockerhub-secret
```

### TLS setup

Person structure application is prepared to use TLS, but requires provided server certificate.
Server certificate is not provided by default (expected to be provided manually) and there are no predefined trust or key stores for TLS/mTLS.
However, there are several different possibilities for customizing TLS setup.

#### Provide server certificate with custom `initContainer`

Key store with custom server certificate can be provided by using custom `initContainer`.
Main thing to keep in mind is that application expects that `initContainer` will output `cert.pem` and `key.pem` files to `volumeMount` with name `server-cert`.
Application will obtain generated certificate and key files via `server-cert` mount and generate server's key store from them.

For example, init container could be defined like this:

```yaml
initContainers:
  - name: generate-server-cert
    image: generate-server-cert
    command:
      - bash
      - -c
      - "custom command to generate certificate"
    volumeMounts:
      - mountPath: /tmp
        name: server-cert # volumeMount name has to be "server-cert"
```

When using initContainer for key store, volume will be stored in memory (`emptyDir: medium: "Memory"`)

#### Provide server certificate from predefined secret

Server certificate can be provided using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of Person structure application.**
Additionally, both certificate and key files should be in one single secret.

When using secret for server certificate, following values have to be provided:

```yaml
mountServerCertFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-server-cert-secret" # string value
  certPath: "name-of-cert-file-from-secret" # string value
  keyPath: "name-of-key-file-from-secret" # string value
```

In this case, Helm chart will take care of mounting certificate and key files to expected location, the only requirement is to set secret name and names of certificate and key files into values file.

#### Provide trust store from custom `initContainer`

If outbound resources (Kafka or database) require TLS connection, trust store with required certificates should also be provided.

One of the options is to provide trust store via custom `initContainer`.

There are some requirements if custom `initContainer` is used for providing trust store.
First, initContainer definition should be added to values file. Besides that, custom `volume`, `volumeMount` and environment variables should be added also.

For example, custom `initContainer` could have this definition:

```yaml
initContainers:
  - name: create-trust-store
    image: create-trust-store-image
    command:
      - bash
      - -c
      - "custom command to generate trust store"
    volumeMounts:
      - mountPath: /any
        name: trust-store-volume-name # has to match custom volume definition
```

Defined `volumeMounts.name` from `initContainer` should also be used to define custom volume, for example:

```yaml
customVolumes:
  - name: trust-store-volume-name # has to match name in initContainer and volumeMount in person-structure container
    emptyDir: # any other volume type is OK
      medium: "Memory"
```

Person-structure container should also mount this volume, so a custom `volumeMount` is required, for example:

```yaml
customMounts:
  - name: trust-store-volume-name # has to match name in initContainer and volumeMount in person-structure container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

Note that `mountPath` variable is used to specify a location of trust store in person-structure container.
Suggested location is: `/mnt/k8s/trust-store`.

To make trust store available to underlying application server, its location (absolute path - `mountPath` and file name) should be defined in following environment variables:

```yaml
customEnv:
  - name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
  - name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_TYPE
    value: JKS # defines provided trust store type (PKCS12, JKS, or other)
  - name: SSL_TRUST_STORE_FILE
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
  - name: JAVAX_NET_SSL_TRUST_STORE
    value: /some/mount/path/trust-store-file # path defined in volumeMount, has to contain full trust store file location
  - name: JAVAX_NET_SSL_TRUST_STORE_PASSWORD
    value: trustStorePassw0rd # password for trust store file
```

#### Provide trust store from predefined secret

Trust store can also be provided by using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of Person structure application.**
Additionally, both certificate and key files should be in one single secret.

When adding trust store as secret, following values have to be provided:

```yaml
mountTrustStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-trust-store-secret" # string value
  location: "/path/to/trust-store" # string value
  trustStoreName: "name-of-trust-store-file-from-secret" # string value
  trustStoreType: "type-of-trust-store" # string value, default is JKS
```

`location` attribute is used to define where trust store file will be located inside container.
Any location is fine, as long as it doesn't override any existing container path.
Suggested location is: `/mnt/k8s/trust-store`.

`trustStoreName` is the actual name of the trust store file itself, as defined in secret.

Those two parameters are joined together to form an absolute path to trust store file.

Default trust store type is JKS and if other type of trust store file is provided, it has to be specified in `trustStoreType` attribute, for example "PKCS12".

Trust store password has to be provided as base64 encoded string in `secret.trustStorePassword` attribute, for example:

```yaml
secret:
  trustStorePassword: "cGFzc3cwcmQ=" # base64 encoded trust store password, default is "changeit"
```

When using secret to mount trust store, no additional custom setup is required.

#### Provide mTLS key store from `initContainer`

mTLS support can also be added to person-structure application in two different ways.

As for trust store, key store could also be provided via custom `initContainer`, with similar requirements.

For example, custom `initContainer` could have this definition:

```yaml
initContainers:
  - name: create-key-store
    image: create-key-store-image
    command:
      - bash
      - -c
      - "custom command to generate key store"
    volumeMounts:
      - mountPath: /any
        name: key-store-volume-name # has to match custom volume definition
```

Defined `volumeMounts.name` from `initContainer` should also be used to define custom volume, for example:

```yaml
customVolumes:
  - name: key-store-volume-name # has to match name in initContainer and volumeMount in person-structure container
    emptyDir: # any other volume type is OK
      medium: "Memory"
```

Person-structure container should also mount this volume, so a custom `volumeMount` is required, for example:

```yaml
customMounts:
  - name: key-store-volume-name # has to match name in initContainer and volumeMount in person-structure container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

Note that `mountPath` variable is used to specify a location of key store in person-structure container.
Suggested location is: `/mnt/k8s/trust-store`.

To make key store available to underlying application server, its location (absolute path - `mountPath` and file name) should be defined in environment variable.
Additionally, key store type should also be defined, for example:

```yaml
customEnv:
  - name: SERVER_SSL_KEY_STORE_FILE
    value: /some/mount/path/key-store-file # path defined in volumeMount, has to contain full key store file location
  - name: SSL_KEY_STORE_TYPE
    value: PKCS12 # defines key store type (PKCS12, JKS, or other)
  - name: SERVER_SSL_KEY_STORE_PASSWORD
    value: keyStorePassw0rd # password for key store file
```

#### Provide mTLS key store from predefined secret

Key store required for mTLS can also be provided via predefined secret.
**Note that this secret has to be created in target namespace prior to installation of Person structure application.**

When adding key store from secret, following values have to be provided:

```yaml
mountKeyStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-key-store-secret" # string value
  location: "/path/to/key-store" # string value
  keyStoreName: "name-of-key-store-file-from-secret" # string value
  keyStoreType: "type-of-key-store" # string value, default is JKS
```

`location` attribute is used to define where key store file will be located inside container (folder structure only).
Any location is fine, as long as it doesn't override any existing container path.
Suggested location is: `/mnt/k8s/key-store`.

`keyStoreName` is the actual name of the key store file itself, as defined in secret.

Those two parameters are joined together to form an absolute path to key store file.

Default key store type is JKS and if other type of key store file is provided, it has to be specified in `keyStoreType` attribute, for example "PKCS12".

Key store password has to be provided as base64 encoded string in `secret.keyStorePassword` attribute, for example:

```yaml
secret:
  keyStorePassword: "cGFzc3cwcmQ=" # base64 encoded trust store password, default is "changeit"
```

When using secret to mount key store, no additional custom setup is required.

## Customizing installation

Besides required attributes, installation of Person structure can be customized in different ways.

### Adding custom environment variables

Custom environment variables can be added to person-structure container by applying `customEnv` value, for example:

```yaml
customEnv:
  - name: MY_CUSTOM_ENV
    value: some-value 
  - name: SOME_OTHER_ENV
    value: 123
```

### Adding custom mounts

Values file can be used to specify additional custom `volume` and `volumeMounts` to be added to person-structure container.

For example, custom volume mount could be added by defining this setup:

```yaml
customVolumes:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in person-structure container
    emptyDir: # any other volume type is OK
      medium: "Memory"

customMounts:
  - name: my-custom-volume # has to match name in initContainer and volumeMount in person-structure container
    mountPath: /some/mount/path # this path should be used for custom environment variables
```

### Customizing container logs

Person structure application is predefined to redirect all logs to `stdout` expect for Web Server logs (`access.log`) and health check logs, which are not logged by default.
However, using custom configuration, logs can be redirected to log files also (in addition to `stdout`).

When enabling logging to file, container will divide logs into four different files:

* `application.log` - contains all application-related (business logic) logs
  
* `messages.log` - contains application server's logs

* `health.log` - contains all incoming requests to health check endpoint (filtered out from `access.log`)

* `access.log` - contains typical Web Server logs, except for health check endpoint

To enable logging to file, following attribute should be set in values file:

```yaml
logger:
  logToFile: true # boolean value, default is false
```

With this basic setup, container will start to log files into a predefined "/var/log/app" location with basic file appender.
In order to set custom log location or to enable rolling file appender, two additional attributes have to be defined:

```yaml
logger:
  logToFile: true # boolean value, default is false
  rollingFileAppender: true # boolean value, default is false
  logDir: "/custom/log/folder"
```

When defining custom log location, make sure folder either already exists in container or is mounted with `logDirMount` variable, for example:

```yaml
logger:
  logToFile: true # boolean value, default is false
  rollingFileAppender: true # boolean value, default is false
  logDir: "/custom/log/folder"
  logDirMount:
    enabled: true # boolean value, default is false
    spec:
      emptyDir: {} # defines mount type, other types can be used also
```

or with other mount type:

```yaml
logger:
  logToFile: true # boolean value, default is false
  rollingFileAppender: true # boolean value, default is false
  logDir: "/custom/log/folder"
  logDirMount:
    enabled: true # boolean value, default is false
    spec:
      flexVolume:
        driver: "volume-driver"
        fsType: "bind"
        options:
          basepath: "/host/path"
          basename: "nope"
          uid: 1000
          gid: 1000
```

Note that any type of mount specification can be used by following standard Kubernetes mount specification, the only requirement is that it has to be defined under `logger.logDirMount.spec` attribute in values file.

### Modifying deployment strategy

Default deployment strategy for Person structure application is `RollingUpdate`, but it can be overridden, along with other deployment parameters using following attributes (default values are shown):

```yaml
deployment:
  replicaCount: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  minReadySeconds: 60
  terminationGracePeriodSeconds: 60
  restartPolicy: Always
```

By default, one replica of Person structure is installed on Kubernetes cluster. Number of replicas can be statically modified with above configuration, or `HorizontalPodAutoscaler` option can be used to let Kubernetes automatically scale application when required.

#### Customizing pod resource requests and limits

Following are the default values for Person structure requests and limits:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 50m
    memory: 256Mi
```

Any value (or all of them) can be modified by specifying same attribute in custom values file to any other value.

#### Using `HorizontalPodAutoscaler`

By default, autoscaler is disabled in configuration, but it can enabled by using following setup:

```yaml
autoscaling:
  enabled: true # default is false, has to be set to true to enable HPA
  minReplicas: 1 # default value
  maxReplicas: 10 # default value
  targetCPUUtilizationPercentage: 80 # default value
  targetMemoryUtilizationPercentage: 80 # not used by default
```

CPU and/or memory utilization metrics can be used to autoscale Person structure pod.
It's possible to define one or both of those metrics.
If only `autoscaling.enabled` attribute is set to `true`, without setting other attributes, only CPU utilization metric will be used with percentage set to 80.

### Customizing probes

Person structure application has predefined health check probes (readiness and liveness).
Following are the default values:

```yaml
deployment:
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 60
    timeoutSeconds: 181
    successThreshold: 1
    failureThreshold: 2
    httpGet:
      path: /health/readiness
      port: http
      scheme: HTTPS
  livenessProbe:
    initialDelaySeconds: 60
    periodSeconds: 60
    timeoutSeconds: 10
    failureThreshold: 3
    httpGet:
      path: /health/liveness
      port: http
      scheme: HTTPS
```

Probes can be modified with different custom attributes simply by setting a different `deployment.readinessProbe` or `deployment.livenessProbe` value structure.

For example, this setup would increase `periodSeconds`, add `httpHeaders` attributes and apply query parameters to `path` of `livenessProbe`:

```yaml
deployment:
  livenessProbe:
    periodSeconds: 180
    httpGet:
      path: /health/liveness?__cbhck=Health/k8s # do not modify base path
      httpHeaders:
        - name: Content-Type
          value: application/json
        - name: User-Agent
          value: Health/k8s
        - name: Host
          value: localhost
```

Note that Person structure has health checks available within the `/health` endpoint (`/health/readiness` for readiness and `/health/liveness` for liveness), and this base paths should not modified, only query parameters are subject to change.
`scheme` attribute should also be set to `HTTPS` at all times, as well as `http` value for `port` attribute.

### Customizing security context

Security context for Person structure can be set on pod and/or on container level.
By default, pod security context is defined with following values:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
```

There is no default security context on container level, but it can be defined by setting `securityContext` attribute (opposed to `podSecurityContext`), for example:

```yaml
securityContext:
  runAsNonRoot: false
  runAsUser: 0
  runAsGroup: 0
```

Note that container level security context will be applied to both containers in Person structure pod (Liquibase init container and Person structure container).

### Customizing network setup

When installing Person structure using default setup, a `Service` object will be created of `ClusterIP` type exposed on port 8443.
Those values can be modified by setting following attributes in custom values file, for example:

```yaml
service:
  type: NodePort
  port: 10000
```

Ingress is not created by default, but can be enabled and customized by specifying following values:

```yaml
ingress:
  enabled: true # default value is false, should be set to true to enable
  className: ""
  annotations: {}
  hosts: []
  tls: []
```

For example, a working setup could be defined like this:

```yaml
ingress:
  enabled: true
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
  hosts:
    - host: person-structure.custom.url
      paths:
        - path: /
          pathType: Prefix
```

### Adding custom init containers

As already explained as one of the options when providing TLS certificates, there's a possibility to define a custom `initContainer`.
This option is not limited to TLS setup only, but custom `initContainer` can be used for any purpose.

Custom init container(s) can simply be added by defining their specification in `initContainers` attribute, for example:

```yaml
initContainers:
  - name: custom-init-container
    image: custom-init-container-image
    command:
      - bash
      - -c
      - "custom command"
  - name: other-custom-init-container
    image: other-custom-init-container-image
    env:
      - name: CUSTOM_ENV_VAR
        value: custom value
```

Init container can have all standard Kubernetes attributes in its specification.

### Customizing affinity rules, node selector and tolerations

Person structure deployment has some predefined affinity rules, as listed below:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/arch
              operator: In
              values:
                - amd64
            - key: kubernetes.io/os
              operator: In
              values:
                - linux
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - person-structure
          topologyKey: kubernetes.io/hostname
```

This affinity rules can be overridden through custom values file and set to any required value if necessary.

There are no defaults for node selector or tolerations, but there is a possibility to define both by adding their specifications, for example:

```yaml
nodeSelector:
  disktype: ssd

tolerations:
  - key: "custom-key"
    operator: "Equal"
    value: "custom-value"
    effect: "NoExecute"
    tolerationSeconds: 3600
```

### Adding custom pod annotations

Custom pod annotations can be added by listing them under `podAnnotations` attribute structure, for example:

```yaml
podAnnotations:
  custom.annotation: custom-value
  other.annotation: other-value
```

### Additional custom configuration

There are some other customizable attributes predefined in Person structure application.

One of them is related to HTTP return code which is returned by application if health check fails.
Default value for this attribute is 418 but it can be customized if necessary, for example:

```yaml
healthStatusDownReturnCode: "499" # default value is 418
```

There's a possibility to define a custom timezone (there is no default one), by simply defining following attribute:

```yaml
timezone: Europe/London
```

Finally, since Person structure is an Java application, there's a possibility to set custom JVM parameters.
There is a predefined value which specifies `Xms` and `Xmx` JVM parameters:

```yaml
javaOpts: "-Xms256M -Xmx256M" # default value
```

This value can be changed by modifying existing parameters or adding custom, for example:

```yaml
javaOpts: "-Xms256M -Xmx512M -Dcustom.jvm.param=true"
```

Note that defining custom `javaOpts` attribute will override default one, so make sure to keep `Xms` and `Xmx` parameters.
