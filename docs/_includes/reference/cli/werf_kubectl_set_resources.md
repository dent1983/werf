{% if include.header %}
{% assign header = include.header %}
{% else %}
{% assign header = "###" %}
{% endif %}
Specify compute resource requirements (CPU, memory) for any resource that defines a pod template.  If a pod is successfully scheduled, it is guaranteed the amount of resource requested, but may burst up to its specified limits.

 For each compute resource, if a limit is specified and a request is omitted, the request will default to the limit.

 Possible resources include (case insensitive): Use &#34;kubectl api-resources&#34; for a complete list of supported resources..

{{ header }} Syntax

```shell
werf kubectl set resources (-f FILENAME | TYPE NAME)  ([--limits=LIMITS & --requests=REQUESTS] [options]
```

{{ header }} Examples

```shell
  # Set a deployments nginx container cpu limits to "200m" and memory to "512Mi"
  kubectl set resources deployment nginx -c=nginx --limits=cpu=200m,memory=512Mi
  
  # Set the resource request and limits for all containers in nginx
  kubectl set resources deployment nginx --limits=cpu=200m,memory=512Mi --requests=cpu=100m,memory=256Mi
  
  # Remove the resource requests for resources on containers in nginx
  kubectl set resources deployment nginx --limits=cpu=0,memory=0 --requests=cpu=0,memory=0
  
  # Print the result (in yaml format) of updating nginx container limits from a local, without hitting the server
  kubectl set resources -f path/to/file.yaml --limits=cpu=200m,memory=512Mi --local -o yaml
```

{{ header }} Options

```shell
      --all=false
            Select all resources, in the namespace of the specified resource types
      --allow-missing-template-keys=true
            If true, ignore any errors in templates when a field or map key is missing in the       
            template. Only applies to golang and jsonpath output formats.
  -c, --containers='*'
            The names of containers in the selected pod templates to change, all containers are     
            selected by default - may use wildcards
      --dry-run='none'
            Must be "none", "server", or "client". If client strategy, only print the object that   
            would be sent, without sending it. If server strategy, submit server-side request       
            without persisting the resource.
      --field-manager='kubectl-set'
            Name of the manager used to track field ownership.
  -f, --filename=[]
            Filename, directory, or URL to files identifying the resource to get from a server.
  -k, --kustomize=''
            Process the kustomization directory. This flag can`t be used together with -f or -R.
      --limits=''
            The resource requirement requests for this container.  For example,                     
            `cpu=100m,memory=256Mi`.  Note that server side components may assign requests          
            depending on the server configuration, such as limit ranges.
      --local=false
            If true, set resources will NOT contact api-server but run locally.
  -o, --output=''
            Output format. One of: json|yaml|name|go-template|go-template-file|template|templatefile
            |jsonpath|jsonpath-as-json|jsonpath-file.
  -R, --recursive=false
            Process the directory used in -f, --filename recursively. Useful when you want to       
            manage related manifests organized within the same directory.
      --requests=''
            The resource requirement requests for this container.  For example,                     
            `cpu=100m,memory=256Mi`.  Note that server side components may assign requests          
            depending on the server configuration, such as limit ranges.
  -l, --selector=''
            Selector (label query) to filter on, supports `=`, `==`, and `!=`.(e.g. -l              
            key1=value1,key2=value2)
      --show-managed-fields=false
            If true, keep the managedFields when printing objects in JSON or YAML format.
      --template=''
            Template string or path to template file to use when -o=go-template,                    
            -o=go-template-file. The template format is golang templates                            
            [http://golang.org/pkg/text/template/#pkg-overview].
```

{{ header }} Options inherited from parent commands

```shell
      --as=''
            Username to impersonate for the operation. User could be a regular user or a service    
            account in a namespace.
      --as-group=[]
            Group to impersonate for the operation, this flag can be repeated to specify multiple   
            groups.
      --as-uid=''
            UID to impersonate for the operation.
      --cache-dir='~/.kube/cache'
            Default cache directory
      --certificate-authority=''
            Path to a cert file for the certificate authority
      --client-certificate=''
            Path to a client certificate file for TLS
      --client-key=''
            Path to a client key file for TLS
      --cluster=''
            The name of the kubeconfig cluster to use
      --context=''
            The name of the kubeconfig context to use
      --insecure-skip-tls-verify=false
            If true, the server`s certificate will not be checked for validity. This will make your 
            HTTPS connections insecure
      --kubeconfig=''
            Path to the kubeconfig file to use for CLI requests.
      --match-server-version=false
            Require server version to match client version
  -n, --namespace=''
            If present, the namespace scope for this CLI request
      --password=''
            Password for basic authentication to the API server
      --profile='none'
            Name of profile to capture. One of (none|cpu|heap|goroutine|threadcreate|block|mutex)
      --profile-output='profile.pprof'
            Name of the file to write the profile to
      --request-timeout='0'
            The length of time to wait before giving up on a single server request. Non-zero values 
            should contain a corresponding time unit (e.g. 1s, 2m, 3h). A value of zero means don`t 
            timeout requests.
  -s, --server=''
            The address and port of the Kubernetes API server
      --tls-server-name=''
            Server name to use for server certificate validation. If it is not provided, the        
            hostname used to contact the server is used
      --token=''
            Bearer token for authentication to the API server
      --user=''
            The name of the kubeconfig user to use
      --username=''
            Username for basic authentication to the API server
      --warnings-as-errors=false
            Treat warnings received from the server as errors and exit with a non-zero exit code
```
