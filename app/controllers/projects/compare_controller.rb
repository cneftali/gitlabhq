require 'addressable/uri'

class Projects::CompareController < Projects::ApplicationController
  include DiffHelper

  # Authorize
  before_action :require_non_empty_project
  before_action :authorize_download_code!
  before_action :assign_ref_vars, only: [:index, :show]
  before_action :merge_request, only: [:index, :show]

  def index
  end

  def show
    compare = CompareService.new.
      execute(@project, @head_ref, @project, @start_ref, diff_options)

    if compare
      @commits = Commit.decorate(compare.commits, @project)

      @start_commit = @project.commit(@start_ref)
      @commit = @project.commit(@head_ref)
      @base_commit = @project.merge_base_commit(@start_ref, @head_ref)

      @diffs = compare.diffs(diff_options)
      @diff_refs = Gitlab::Diff::DiffRefs.new(
        base_sha: @base_commit.try(:sha),
        start_sha: @start_commit.try(:sha),
        head_sha: @commit.try(:sha)
      )

      @diff_notes_disabled = true
      @grouped_diff_notes = {}
    end
  end

  def create
    redirect_to namespace_project_compare_path(@project.namespace, @project,
                                               params[:from], params[:to])
  end

  private

  def assign_ref_vars
    @start_ref = Addressable::URI.unescape(params[:from])
    @ref = @head_ref = Addressable::URI.unescape(params[:to])
  end

  def merge_request
    @merge_request ||= @project.merge_requests.opened.
      find_by(source_project: @project, source_branch: @head_ref, target_branch: @start_ref)
  end
end
