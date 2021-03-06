class Project < ActiveRecord::Base
  attr_accessible :name, :token, :tech_stack, :region,
    :github_account, :github_project, :github_private,
    :aws_access_key, :aws_secret_access_key, :aws_key_name, :url

  validates_presence_of :name

  after_create :assign_deploy_key, :assign_github_deploy_key, :launch_dashboard, :launch_ci

  def launch_dashboard
    Dupondius::Aws::CloudFormation::Dashboard.new(self.name, 'Ruby on Rails',
                                                  self.region, self.github_account, self.aws_key_name, {
        InstanceType: 'm1.small',
        DBName: 'dashboard',
        DBUsername: 'dashboard',
        DBPassword: 'dashboard',
        DBRootPassword: 'r00tr00t',
        AwsAccessKey: self.aws_access_key,
        AwsSecretAccessKey: self.aws_secret_access_key,
        KeyName: self.aws_key_name
    }).create
  end

  def dashboard
    @dashboard ||= Dupondius::Aws::CloudFormation::Dashboard.find(self.name, self.region)
  end

  # github deploy key is used by CI to pull code
  def github_deploy_key
    SSHKey.new(read_attribute(:github_deploy_key))
  end

  # deploy key is used by the deployment process (CAP) to deploy code via ssh
  def deploy_key
    SSHKey.new(read_attribute(:deploy_key))
  end

  private

  def assign_github_deploy_key
    self.github_deploy_key= SSHKey.generate.private_key
    save!

    github_client= Octokit::Client.new(:login => self.github_account, :oauth_token => self.token)
    github_client.add_deploy_key(Octokit::Repository.from_url(self.url), 'dupondius deploy key', self.github_deploy_key.ssh_public_key)
  end

  def assign_deploy_key
    self.deploy_key= SSHKey.generate.private_key
    save!
    s3 = AWS::S3.new(
      :access_key_id     => Dupondius.config.access_key,
      :secret_access_key => Dupondius.config.secret_access_key
    )
    bucket = s3.buckets[Dupondius.config.config_bucket]
    public_key = bucket.objects["#{self.name}.pub"]
    public_key.write(self.deploy_key.ssh_public_key)
    public_key.acl= :public_read
  end

  def launch_ci
    options = {
        AwsAccessKey: self.aws_access_key,
        AwsSecretAccessKey: self.aws_secret_access_key,
        KeyName: self.aws_key_name,
        InstanceType: 'm1.small',
        ProjectGithubUser: self.github_account,
        ProjectType: 'rails',
        GithubDeployPrivateKey: self.github_deploy_key.private_key,
        DeployPrivateKey: self.deploy_key.private_key
    }
    Dupondius::Aws::CloudFormation::ContinuousIntegration.create(self.name, 'Ruby on Rails', self.region, options)
  end

  handle_asynchronously :launch_dashboard
  handle_asynchronously :launch_ci
end
