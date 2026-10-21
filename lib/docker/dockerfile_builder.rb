# frozen_string_literal: true

require 'fileutils'

class DockerfileBuilder
  def initialize(metadata_dir: 'metadata')
    @metadata_dir = metadata_dir
  end

  def generate(variant)
    validate_variant!(variant)

    config = load_config(variant)
    validate_config!(config)

    lines = [
      "FROM #{config.fetch('base_image')}",
      "LABEL maintainer=\"#{config.fetch('maintainer')}\"",
    ]
    env_list = config.fetch('env', []).join(' ')
    version = config.fetch('version', '8')
    lines.push("ENV #{env_list}")

    commands = [
      'apt-get update',
      'apt-get install -y --no-install-recommends curl ca-certificates',
      '. /etc/os-release',
      'RELEASE="${ID}${VERSION_ID}"',
      "curl -fsSLo /tmp/openvox-release.deb \"https://apt.voxpupuli.org/openvox#{version}-release-${RELEASE}.deb\"",
      'dpkg -i /tmp/openvox-release.deb',
      'rm -f /tmp/openvox-release.deb',
      'apt-get update',
      'apt-get purge -y --auto-remove curl',
      'apt-get install -y --no-install-recommends openvox-agent',
      'echo "OpenVox release: ${RELEASE}"',
      'set +e; FACTER_hostname="' + variant + '" /opt/puppetlabs/bin/puppet apply /puppet/manifests/init.pp --detailed-exitcodes --verbose --summarize --hiera_config=/puppet/hiera.yaml --modulepath=/puppet/modules; PUPPET_STATUS=$?; set -e; echo "Puppet exit code: $PUPPET_STATUS"; if [ "$PUPPET_STATUS" -ne 0 ] && [ "$PUPPET_STATUS" -ne 2 ]; then exit "$PUPPET_STATUS"; fi',
      'apt-get purge -y --auto-remove openvox-agent',
      'apt-get clean',
      'rm -rf /opt/puppetlabs',
      'rm -rf /etc/puppet/',
      'rm -rf /var/lib/apt/lists/*',
    ]

    mounts = [
      '--mount=type=bind,source=.,target=/puppet',
    ]
    lines.push("RUN #{mounts.join(" && \\\n    ")} #{commands.join(" && \\\n    ")}")
    workdir = config.fetch('workdir', nil)
    lines.push("WORKDIR #{workdir}") if workdir
    user = config.fetch('user', nil)
    lines.push("USER #{user}") if user

    "#{lines.join("\n")}\n"
  end

  private

  def validate_variant!(variant)
    pattern = %r{\A
      [a-z0-9]+(?:[._-][a-zA-Z0-9]+)*(?:/[a-z0-9]+(?:[._-][a-zA-Z0-9]+)*)*
      :
      [a-zA-Z0-9_][a-zA-Z0-9_.-]{0,127}
    \z}x

    return if variant.match?(pattern)

    raise ArgumentError, "Invalid variant: #{variant.inspect}"
  end

  def load_yaml(path)
    raise "Missing YAML file: #{path}" unless File.file?(path)

    data = YAML.safe_load_file(path, aliases: false) || {}

    unless data.is_a?(Hash) &&
           data.all? { |key, _value| key.is_a?(String) }
      raise ArgumentError, "#{path} must contain a flat YAML mapping"
    end

    data
  end

  def load_config(variant)
    common = load_yaml(
      File.join(@metadata_dir, 'metadata.yaml'),
    )

    variant_path = File.join(@metadata_dir, "#{variant}.yaml")
    specific = if File.file?(variant_path)
                 load_yaml(variant_path)
               else
                 {}
               end
    result = common.merge(specific)
    result.store('image_name', variant)
    result
  end

  def validate_config!(config)
    required = %w[
      maintainer
      image_name
      base_image
    ]

    missing = required.select do |key|
      !config.key?(key) || config[key].to_s.empty?
    end

    return if missing.empty?

    raise ArgumentError,
          "Missing required metadata: #{missing.join(', ')}"
  end
end
