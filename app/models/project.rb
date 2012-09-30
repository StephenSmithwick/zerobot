class Project < ActiveRecord::Base
  attr_accessible :name, :token, :tech_stack, :region, :github_account, :github_project, :github_private

  validates_presence_of :name

  after_create :launch_dashboard

  def launch_dashboard
    # temporarily guard the creation of aws resources
    Dupondius::Aws::CloudFormation::Dashboard.new(self.name, self.tech_stack, self.region,  {
        InstanceType: 'm1.small',
        DBName: 'dashboard',
        DBUsername: 'dashboard',
        DBPassword: 'dashboard',
        DBRootPassword: 'r00tr00t'
    }).create
  end

  handle_asynchronously :launch_dashboard

  def dashboard
    @dashboard ||= Dupondius::Aws::CloudFormation::Dashboard.find(self.name, self.region)
  end

end
