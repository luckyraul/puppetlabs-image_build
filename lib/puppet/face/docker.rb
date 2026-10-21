# frozen_string_literal: true

# lib/puppet/face/docker.rb
require 'puppet/face'
require_relative '../../docker/dockerfile_builder'
require_relative '../../docker/docker_image_builder'

Puppet::Face.define(:docker, '3.0.0') do
  summary 'Build Docker images from Puppet code'
  option '--image-name STRING' do
    summary 'The name of the resulting image'
    default_to { 'puppet/constructed-image' }
  end
  action(:build) do
    summary 'Build a Docker image from Puppet code'
    when_invoked do |*options|
      args = options.pop
      variant = args[:image_name]
      file_builder = DockerfileBuilder.new
      content = file_builder.generate(variant)
      File.write('Dockerfile', content)
      image_builder = DockerImageBuilder.new
      image_builder.build(dockerfile: 'Dockerfile', tag: 'test2')
    end
  end
  action(:dockerfile) do
    summary 'Generate a Dockerfile which will run the specified Puppet code'
    when_invoked do |*options|
      args = options.pop
      variant = args[:image_name]
      builder = DockerfileBuilder.new
      puts builder.generate(variant)
    end
  end
end
