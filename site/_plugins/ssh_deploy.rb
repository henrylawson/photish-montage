class Photish::Plugin::SshDeploy

  def initialize(config, log)
    @config = config
    @log = log
  end

  def deploy_site
    log.info "Publishing website to #{host}"

    log.info "Cleaning temp locations and ensuring directories exist"
    execute("ssh #{host} -v '" +
            "mkdir -p #{publish_temp_dir} && " +
            "rm -rf #{publish_temp_dir}/* && " +
            "mkdir -p #{upload_temp_dir} && " +
            "rm -rf #{upload_temp_dir}/*" +
            "'")

    log.info "Creating tar gz of photish site"
    execute("GZIP=-9 tar -zcvf " +
            "#{output_dir_compress_file} " +
            "-C #{output_dir} .")

    log.info "Uploading site to upload temp location"
    execute("rsync -v " +
            "-e 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null' " +
            "--progress #{output_dir_compress_file} " +
            "#{host}:#{upload_temp_dir}")

    log.info "Extracting site to publish temp location"
    execute("ssh #{host} -v " +
            "'tar -zxvf " +
            "#{upload_temp_dir}/#{output_dir_compress_filename} " +
            "-C #{publish_temp_dir}'")

    log.info "Moving publish temp to publish folder"
    execute("ssh #{host} -v " +
            "'sudo su #{www_user} bash -c \"" +
            "mkdir -p #{publish_dir} && " +
            "rm -rf #{publish_dir}/* && " +
            "cp -rf #{publish_temp_dir}/* #{publish_dir}\"'")
    log.info "#{Time.new}: Deployment complete"
  ensure
    FileUtils.rm_rf(output_dir_compress_file)
  end

  private

  attr_reader :config,
              :log

  delegate :deploy,
           :output_dir,
           to: :config

  delegate :host,
          :publish_dir,
          :publish_temp_dir,
          :upload_temp_dir,
          :www_user,
          to: :deploy

  def output_dir_compress_filename
    'output_dir.tar.gz'
  end

  def output_dir_compress_file
    @output_dir_compress_file ||= File.join(Dir.mktmpdir,
                                            output_dir_compress_filename)
  end

  def self.is_for?(type)
    [
      Photish::Plugin::Type::Deploy
    ].include?(type)
  end

  def self.engine_name
    'ssh'
  end

  def execute(command)
    log.info "Executing: #{command}"
    system("#{command}") || exit(1)
  end
end
