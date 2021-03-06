
class Aws::StacksController < ApplicationController

  respond_to :json

  rescue_from 'AWS::CloudFormation::Errors::ValidationError' do |error|
    render :json => {:error => error.message}, :status => 400
  end

  def index
    respond_with(Dupondius::Aws::CloudFormation.summaries)
  end

  def show
    stack = Dupondius::Aws::CloudFormation::Stack.find(params[:id])
    if stack
      respond_with(stack)
    else
      render :nothing => true, :status => 404
    end
  end

  def update
    stack = Dupondius::Aws::CloudFormation::Stack.find(params[:id])
    stack.update(params[:parameters])
    render :json => {:success => true}, :status => 200
  end

  def create
    full_name = params[:parameters][:EnvironmentName]
    full_name.concat("-#{params[:parameters][:UniqueName]}") if params[:parameters][:EnvironmentName] == 'dev'
    params[:parameters].delete(:UniqueName)
    params[:parameters].delete(:EnvironmentName) if params[:parameters][:EnvironmentName] == 'ci'
    result = Dupondius::Aws::CloudFormation::Stack.create(params[:templateName],
                                                     full_name,
                                                     Dupondius.config.project_name,
                                                     params[:parameters])

    render :json => {:success => true}, :status => 200
  end

  def destroy
    Dupondius::Aws::CloudFormation::Stack.find(params[:id]).delete
    render :nothing => true, :status => 200
  end

  def available
    stacks = Dupondius::Aws::CloudFormation::ENVIRONMENTS
    respond_with(stacks.map { | name | { :name => name } })
  end

  def template
    respond_with(Dupondius::Aws::CloudFormation::Stack.find(params[:id]).template)
  end

end
