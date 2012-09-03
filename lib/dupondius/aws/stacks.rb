module Dupondius; module Aws; module CloudFormation

  def self.access
    @cfn ||= AWS::CloudFormation.new(:access_key_id => Dupondius::Aws::Config.access_key,
       :secret_access_key => Dupondius::Aws::Config.secret_access_key)
  end

  def self.summaries project_name, status = :create_complete
    Dupondius::Aws::CloudFormation.access.stack_summaries.with_status(status).select do |s|
      s if s[:stack_name] =~ /.*#{project_name}$/
    end
  end

  class Stack
    def initialize subject
      @subject = subject
    end

    def method_missing(sym, *args, &block)
      @subject.send sym, *args, &block
    end

    def self.find stack_name
      stack = Dupondius::Aws::CloudFormation.access.stacks[stack_name]
      stack.exists? ? self.new(stack) : nil
    end

    def self.create template_name, environment_name, project_name, parameters
      Dupondius::Aws::CloudFormation.access.stacks.create("#{environment_name}-#{project_name}", load_template(template_name),
        :parameters => parameters.merge({HostedZone: Dupondius::Aws::Config.hosted_zone, ProjectName: project_name}))
    end

    def self.template_params template_name
      puts Dupondius::Aws::CloudFormation.access.validate_template(load_template(template_name))
      Dupondius::Aws::CloudFormation.access.validate_template(load_template(template_name))[:parameters].collect { |p| p[:parameter_key] }
    end

    def self.load_template template_name
      File.open(File.expand_path(File.join( File.dirname(__FILE__), '..', 'aws', 'templates', "#{template_name}.template")), 'rb').read
    end

    def complete?
      @subject.status == 'CREATE_COMPLETE'
    end

    def stop_ec2
    end

    def start_ec2
    end

  end

  class ContinuousIntegration < Stack

    def self.create project_name, parameters
      super('jenkins', 'ci', project_name, parameters)
    end

    def self.find project_name
      super("ci-#{project_name}")
    end
  end


  class Dashboard < Stack

    def self.create project_name, parameters
      super('rails_single_instance', 'dashboard', project_name, parameters)
    end

    def self.find project_name
      super("dashboard-#{project_name}")
    end

    def self.template_params
      super("rails_single_instance")
    end

    def self.load_json template_name
      template= super(template_name)
      JSON.parse(template)

      # inject the dashboard install script into the user-data
      user_data = template['Resources']['WebServer']['Properties']['UserData']['Fn::Base64']['Fn::Join'].last
      user_data.insert((user_data.size) -4, "curl -L https://s3.amazonaws.com/dupondius/config/install-dashboard | bash \n")
      JSON.pretty_generate(template)
    end
  end
end; end; end
