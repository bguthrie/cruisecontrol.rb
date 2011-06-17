class BuildsController < ApplicationController
  caches_page :drop_down
  
  def show
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project

    if params[:build]
      @build = @project.find_build(params[:build])
      render :text => "Build #{params[:build].inspect} not found", :status => 404 and return if @build.nil? 
    else
      @build = @project.last_build
      render :action => 'no_builds_yet' and return if @build.nil?
    end

    @builds_for_navigation_list, @builds_for_dropdown = partitioned_build_lists(@project)

    @autorefresh = @build.incomplete?
  end

  def artifact
    render :text => 'Project not specified', :status => 404 and return unless params[:project]
    render :text => 'Build not specified', :status => 404 and return unless params[:build]
    render :text => 'Path not specified', :status => 404 and return unless params[:path]

    @project = Project.find(params[:project])
    render :text => "Project #{params[:project].inspect} not found", :status => 404 and return unless @project

    @build = @project.find_build(params[:build])
    render :text => "Build #{params[:build].inspect} not found", :status => 404 and return unless @build

    path = Pathname.new(@build.artifact(params[:path]))

    if path.exist?
      if path.directory?
        if path.join('index.html').exist?
          redirect_to request.fullpath + '/index.html'
        else
          render :text => "this should be an index of #{params[:path]}"
        end
      else
        
        send_file(path.to_s, :type => get_mime_type(path), :disposition => 'inline', :stream => false)
      end
    else
      render :text => "File #{path} does not exist", :status => 404
    end
  end
  
  private

    MIME_TYPES = {
      "html" => "text/html",
      "js"   => "text/javascript",
      "css"  => "text/css",
      "gif"  => "image/gif",
      "jpg"  => "image/jpeg",
      "jpeg" => "image/jpeg",
      "png"  => "image/png",
      "zip"  => "application/zip"
    }

    DEFAULT_MIME_TYPE = "text/plain"

    def get_mime_type(path)
      extension = path.extname.downcase[1..-1]
      MIME_TYPES[extension] || DEFAULT_MIME_TYPE
    end

    def partitioned_build_lists(project)
      builds = project.builds.reverse
      partition_point = Configuration.build_history_limit

      return builds[0...partition_point], builds[partition_point..-1]
    end

end