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

Person structure application relies on PostgreSQL database and Kafka backends.
In order to assure connectivity to those backends, it's required to set basic info into values file.

### Datasource connection setup

All values required for PostgreSQL database connection are defined within `datasource` parent attribute.
Application will not be able to connect to database if all attributes are not filled.

Datasource attributes:

```yaml
datasource:
  host: "db-hostname" # only PostgreSQL hostname has to be defined (for instance "localhost")
  port: 5432 # PostgreSQL port number 
  dbName: "database-name" # Name of PostgreSQL database
  user: "database-user" # User which application will use to connect to PostgreSQL
  liquibaseUser: "liquibase-user" # User which LiquiBase container will use to apply database changes
  schema: "database-schema" # PostgreSQL schema for Person structure application
```

In addition to datasource attributes, it's required to provide an AES encrypted password for database user specified in `datasource.user`, as well as base64 encoded user for LiquiBase user defined in `datasource.liquibaseUser`.

Encryption key used to encrypt and decrypt datasource password (as well as Kafka passwords) is defined in `secret.decryptionKey` attribute.
Use this key to encrypt datasource password and define it in `secret.datasourcePassword`.

Password for LiquiBase user (which will apply database changes for each version) has to be base64 encoded, and is not related to `secret.decryptionKey` attribute.

Datasource secret configuration:

```yaml
secret:
  decryptionKey: "my-encryption-key" # some custom encryption key
  datasourcePassword: "{AES}S0m3H4sh" # datasource password for user defined in datasource.user encrypted with custom encryption key
  liquibasePassword: "S0m3H4sh" # base64 encoded password for Liquibase user defined in datasource.liquibaseUser attribute
```

### Kafka connection setup

Person structure uses Kafka as event stream provider.
Other than Kafka cluster itself, Person structure application also uses Kafka Schema Registry, which setup also has to be provided in order to establish required connection.

To connect to Kafka cluster, several attributes have to be defined in values file.
All attributes under `kafka` parent attribute are required:

```yaml
kafka:
  user: "kafka-user" # string value
  servers: "kafka-server:port" # string value
  schemaRegistry:
    user: "kafka-schema-registry-user" # string value
    url: "kafka-schema-registry-url" # string value
```

## Custom installation

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

**TODO:** nastavak

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

Note that any type of mount specification can be used by following standard Kubernetes mount specification, the only requirement is that it has to be defined under `logger.logDir.spec` attribute in values file.

### TLS setup

Person structure application is prepared to use TLS with provided server certificate.
Server certificate is not provided by default (expected to be provided manually) and there are no predefined trust or key stores for TLS/mTLS.
However, there are several different possibilities for customizing TLS setup.

#### Provide server certificate with custom initContainer

Key store with custom server certificate can be provided by using custom initContainer.
Main thing to keep in mind is that application expects that initContainer will output `cert.pem` and `key.pem` files to `volumeMount` with `server-cert` name.
Application will take provided certificate and key files and generate key store from them.

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

**TODO:** opis koji tip certifikata, algoritam i sl.

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

#### Provide trust store from custom initContainer

If outbound resources (Kafka or database) require TLS connection, trust store with required certificates should also be provided.

One of the options is to provide trust store via custom `initContainer`.

There are some requirements if custom initContainer is used for providing trust store.
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
To make trust store available to underlying application server, its location should be defined in following environment variables:

```yaml
customEnv:
  - name: SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION
    value: /some/mount/path # this is the path defined in volumeMount and has to contain full trust store file location
  - name: SSL_TRUST_STORE_FILE
    value: /some/mount/path # this is the path defined in volumeMount and has to contain full trust store file location
  - name: JAVAX_NET_SSL_TRUST_STORE
    value: /some/mount/path # this is the path defined in volumeMount and has to contain full trust store file location
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
```

`location` attribute is used to define where trust store file will be located inside container.
Any location is fine, as long as it doesn't override any existing container path.

`trustStoreName` is the actual name of the trust store file itself, as defined in secret.

Those two parameters are joined together to form an absolute path to trust store file.

When using secret to mount trust store, no additional custom setup is required.

#### Provide mTLS key store from initContainer

mTLS support can also be added to person-structure application in two different ways.

As for trust store, key store could also be provided via custom initContainer, with similar requirements.

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
To make key store available to underlying application server, its location should be defined in environment variable.
Additionally, key store type should also be defined, for example:

```yaml
customEnv:
  - name: SERVER_SSL_KEY_STORE_FILE
    value: /some/mount/path # this is the path defined in volumeMount and has to contain full key store file location
  - name: SSL_KEY_STORE_TYPE
    value: PKCS12 # define key store type (PKCS12, JKS, or other)
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
```

`location` attribute is used to define where key store file will be located inside container (folder structure only).
Any location is fine, as long as it doesn't override any existing container path.

`keyStoreName` is the actual name of the key store file itself, as defined in secret.

Those two parameters are joined together to form an absolute path to key store file.

When using secret to mount key store, no additional custom setup is required.
