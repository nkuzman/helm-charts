# Person structure application

## Purpose

**TODO** dodati opis

## Default Installation

This Helm chart installs Person structure into your Kubernetes cluster.

Helm release name set during installation will be used for naming all resources created by this Helm chart. For example, if Chart is installed with name "my-chart", deployment name will have "my-chart" prefix, as well as all configmaps, secrets and other resources created by this chart.

It is not possible to install application using default values only, there is a list of required attributes which should be applied when installing Person structure.

Required attributes should be defined in custom `values.yaml` file or propagated with `--set key=value` command during CLI installation, for example:

`helm upgrade --install person-structure vestigo/person-structure -f my-values.yaml` or

`helm upgrade --install person-structure vestigo/person-structure --set required-key1=value1 --set required-key2=value2 ...`

Required values are (in `yaml` format):

```yaml
secret:
  decryptionKey: "my-encryption-key" # string value
  datasourcePassword: "AES-encoded-datasource-password" # string value
  kafkaPassword: "AES-encoded-kafka-password" # string value
  kafkaSchemaRegistryPassword: "AES-encoded-kafka-schema-registry-password" # string value
  liquibasePassword: "Base-64-encoded-password-for-LiquiBase-user" # string value

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

## Custom installation

Besides required attributes, installation of Person structure can be customized in different ways.

### TLS setup

Person structure application will be run using generated self-signed certificate by default, if custom TLS setup is not provided.
There are several different possibilities for defining TLS.

#### Provide key store with custom initContainer

Key store with custom server certificate can be provided by using custom initContainer.
Main thing to keep in mind is that application expects that initContainer will output `cert.pem` and `key.pem` files to `volumeMount` with `keystore` name.
Application will take provided certificate and key files and generate key store from them.

For example, init container could be defined like this:

```yaml
initContainers:
  - name: create-cacert
    securityContext:
      runAsUser: 0
      runAsGroup: 0
    image: create-cacert-image
    imagePullPolicy: Always
    command:
      - bash
      - -c
      - "custom command to generate certificate"
    volumeMounts:
      - mountPath: /var/tmp
        name: keystore # volumeMount name has to be "keystore"
```

When using initContainer for key store, volume will be stored in memory (`emptyDir: medium: "Memory"`)

### Provide key store from predefined secret

**TODO:** opis koji tip certifikata, algoritam i sl.

Key store can be provided by using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of Person structure application.**
Additionally, both certificate and key files should be in one single secret.

When using secret, following values have to be provided:

```yaml
mountKeyStoreFromSecret:
  enabled: true # boolean value, default is false
  secretName: "name-of-secret-with-key-store" # string value
  certPath: "name-of-cert-file-from-secret" # string value
  keyPath: "name-of-key-file-from-secret" # string value
```

In this case, Helm chart will take care of mounting certificate and key files to expected location, the only requiremenet is to set secret name and names of certificate and key files into values file.

### Provide trust store from custom initContainer

**TODO** dodati opis

### Provide trust store from predefined secret

If outbound resources (Kafka or database) require TLS connection, trust store with required certificates should also be provided.

Trust store can be provided by using predefined secret.
**Note that this secret has to be created in target namespace prior to installation of Person structure application.**
Additionally, both certificate and key files should be in one single secret.

**TODO** ostatak opisa
