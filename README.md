# Ansible: Lego Ansible Role

[![lint](https://github.com/elan-ev/lego/actions/workflows/lint.yml/badge.svg?branch=main)](https://github.com/elan-ev/lego/actions/workflows/lint.yml?branch=main)
[![molecule](https://github.com/elan-ev/lego/actions/workflows/molecule.yml/badge.svg?branch=main)](https://github.com/elan-ev/lego/actions/workflows/molecule.yml?branch=main)

This role deploys [Lego](https://github.com/go-acme/lego) and obtains certificates for the specified domain(s). It can be used multiple times to obtain multiple certificates. The configuration is split into

- global options:
    - Lego arguments and environment variables used for all domains
- domain specific options:
    - Lego arguments and environment variables used only for this specific domain

The Lego run/renew command is build with this pattern:

```
<global-env-vars> \
<domain-specific-env-vars> \
lego <global-arguments> \
     <domain-specific-arguments> \
     --domain <domain> \
     renew --renew-hook <renew-hook>
```

## Dependencies

No dependencies required.

## Role Variables

- `lego_email`:
    - Domain administrators email address. It will be passed to the ACME provider (e.g. LetsEncrypt).
    - Required

- `lego_domains`:
    - List of domain names to obtain a certificate for. All but the first domain will be set as certificate alternative names.
    - Default: `["{{ inventory_hostname }}"]`

- `lego_extra_args`:
    - List of additional lego arguments to be applied. For available options please take a look at [Lego documentation](https://go-acme.github.io/lego/usage/cli/options/index.html).
    - Default: `[]`

- `lego_domain_extra_args`:
    - List of additional lego arguments to be applied for this specific domain only. For available options please take a look at [Lego documentation](https://go-acme.github.io/lego/usage/cli/options/index.html).
    - Default: `[]`

- `lego_env_vars`:
    - List of environment variables for lego. This allows you to apply additional configuration without directly modifying extra arguments. It can be used for setting DNS provider configuration, especially API keys.
    - Default: `[]`

- `lego_domain_env_vars`:
    - List of environment variables for lego for this specific domain only. This allows you to apply additional configuration without directly modifying extra arguments. It can be used for setting DNS provider configuration, especially API keys.
    - Default: `[]`

- `lego_hook`:
    - Lego run/renew certificate hook. The hook is executed only when the certificates are effectively obtained/renewed.
    - Default:

- `lego_link_certificate_path`:
    - Directory path to link certificate and key to. The directory must exist. If unset or empty, no link operations will occur.
    - Default:

- `lego_link_certificate_file_name`:
    - If `lego_link_certificate_path` is set, the certificate will be linked to the path `{{ lego_link_certificate_path }}/{{ lego_link_certificate_file_name }}`.
    - Default: `{{ lego_domains | first }}.crt`

- `lego_link_certificate_key_file_name`:
    - If `lego_link_certificate_path` is set, the certificate key will be linked to the path `{{ lego_link_certificate_path }}/{{ lego_link_certificate_key_file_name }}`.
    - Default: `{{ lego_domains | first }}.key`

- `lego_link_certificate_reload_service_name`:
    - If `lego_link_certificate_path` is set and the certificate is linked, the service with the given name will be reloaded. An empty value will disable the handler.
    - Default:

- `lego_link_certificate_restart_service_name`:
    - If `lego_link_certificate_path` is set and the certificate is linked, the service with the given name will be restarted. An empty value will disable the handler.
    - Default:

## Example Playbook

A minimal example to obtain a certificate with lego without using an external webserver:

```yaml
- hosts: servers
  become: true
  roles:
    - role: elan.lego
      lego_email: admin@mydomain.org
      lego_extra_args:
        - "--http"
```

An example of using this role to obtain a certificate using an external webserver (e.g. Nginx). The webserver should be configured to deliver files from `/var/lib/nginx/.well-known/acme-challenge` over http under the URL path `/.well-known/acme-challenge`. On each certificate update, the webserver should be reloaded.

For more information about ACME HTTP challenges please take a look at [Documentation](https://letsencrypt.org/docs/challenge-types/#http-01-challenge).

```yaml
- hosts: servers
  become: true
  roles:
    - webserver
    - role: elan.lego
      lego_email: admin@mydomain.org
      lego_extra_args:
        - "--http"
        - "--http.webroot /var/lib/nginx"
      lego_hook: "systemctl reload nginx"
```

An example of using this role to obtain a certificate over DNS challenge. This example uses [deSEC.io](https://go-acme.github.io/lego/dns/desec/index.html) as a DNS provider. The certificate should cover additional alternative domain names. Last but not least, our webapp should be reloaded on each certificate update.

```yaml
- hosts: servers
  become: true
  roles:
    - role: elan.lego
      lego_email: admin@mydomain.org
      lego_domains:
        - "{{ inventory_hostname }}"
        - mydomain.org
        - sub.mydomain.org
      lego_extra_args:
        - "--dns desec"
      lego_env_vars:
        - "DESEC_TOKEN={{ desec_api_token }}"
      lego_hook: "systemctl reload mywebapp"
```

Development Environment
----------------

For linting and role development you can use the tools defined in [development requirements](.dev_requirements.txt).
You can quickly install them in a python virtual environment like this:

```sh
# Create a virtual environment
python -m venv venv
# Activate the virtual environment
. venv/bin/activate
# Install the dependencies
pip install -r .dev_requirements.txt
```

This way, you can run the linter (`ansible-lint`).

For development and testing you can use [molecule](https://molecule.readthedocs.io/en/latest/).
With podman as driver you can install it like this – preferably in a virtual environment:

```bash
pip install -r .dev_requirements.txt
```

Then you can *create* the test instances, apply the ansible role (*converge*) and *destroy* the test instances with these commands:

```bash
molecule create
molecule converge
molecule destroy
```

Or simply run `molecule test` to do all steps at once.

If you want to inspect a running test instance, use `molecule login --host <instance_name>` where you replace `<instance_name>` with the desired value.
