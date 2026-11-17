# frozen_string_literal: true

require 'fileutils'
require 'open3'

class DockerImageBuilder
  class BuildError < StandardError; end

  def build(dockerfile:, tag:, context: nil)
    dockerfile = File.expand_path(dockerfile)
    context = File.expand_path(context || File.dirname(dockerfile))

    raise ArgumentError, "Dockerfile not found: #{dockerfile}" unless
      File.file?(dockerfile)

    raise ArgumentError, "Build context not found: #{context}" unless
      File.directory?(context)

    command = [
      'docker',
      'build',
      '--progress=plain',
      '--file', dockerfile,
      '--tag', tag,
      context,
    ]

    run(command)
  end

  private

  def run(command)
    status = nil

    Open3.popen2e(*command) do |_stdin, output, wait_thread|
      output.each { |line| print line }
      status = wait_thread.value
    end

    return if status&.success?

    raise BuildError,
          "Docker build failed with exit status #{status&.exitstatus}"
  end
end
