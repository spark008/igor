# Methods for rendering generic UI icons.
module IconsHelper
  # Tells the user that his input is valid.
  def valid_icon_tag
    title = 'Valid input'
    image_tag 'icons/checkmark.png', alt: title, title: title, class: 'ui-icon'
  end

  # Tells the user that his input has some errors.
  def invalid_icon_tag
    title = 'Invalid input'
    image_tag 'icons/error.png', alt: title, title: title, class: 'ui-icon'
  end

  # Tells the user that some lengthy computation or process is in progress.
  def waiting_icon_tag
    title = 'In progress'
    image_tag 'icons/waiting.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on links to the next step in a multi-step process.
  def next_step_icon_tag
    title = 'Next step'
    image_tag 'icons/next.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that lead to creating data.
  def create_icon_tag
    title = 'Create item'
    image_tag 'icons/add.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that delete some data (e.g. ActiveRecord.destroy).
  def destroy_icon_tag
    title = 'Remove'
    image_tag 'icons/destroy.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on links that lead to an edit form.
  def edit_icon_tag
    title = 'Edit'
    image_tag 'icons/edit.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that commit information to the database.
  def save_icon_tag
    title = 'Save'
    image_tag 'icons/save.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that lead to an edit form.
  def search_icon_tag
    title = 'Search'
    image_tag 'icons/search.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on links that lead to printable material.
  def print_icon_tag
    title = 'Print'
    image_tag 'icons/print.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that generate a table out of existing data.
  def report_icon_tag
    title = 'Generate report'
    image_tag 'icons/report.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on links that lead to a help screen.
  def help_icon_tag
    title = 'Help'
    image_tag 'icons/help.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that release some data to the public.
  def ship_icon_tag
    title = 'Ship it!'
    image_tag 'icons/release.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that pull back previously released data.
  def pull_icon_tag
    title = 'Pull data'
    image_tag 'icons/revert.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that lead to a file download.
  def download_icon_tag
    title = 'Download file'
    image_tag 'icons/download.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that lead to a potentially lengthy file upload.
  def upload_icon_tag
    title = 'Upload file'
    image_tag 'icons/upload.png', alt: title, title: title, class: 'ui-icon'
  end

  # Shown on buttons that cause an expensive re-computation of cached state.
  def recompute_icon_tag
    title = 'Recompute'
    image_tag 'icons/recompute.png', alt: title, title: title, class: 'ui-icon'
  end

  # Access levels / roles throughout the site.
  def role_icon_tag(role = :student)
    case role
    when :student
      title = 'Student'
      path = 'icons/student.png'
    when :staff
      title = 'Course Staff'
      path = 'icons/staff.png'
    when :team
      title = 'Team'
      path = 'icons/team.png'
    when :public
      title = 'Public'
      path = 'icons/public.png'
    else
      raise "Unknown role #{role}!"
    end
    image_tag path, alt: title, title: title, class: 'ui-icon'
  end

  # The icon that communicates an assignment's state to the user.
  def assignment_state_icon_tag(state = :open)
    case state
    when :draft
      title = 'Under construction'
      path = 'icons/draft.png'
    when :open
      title = 'Accepting submissions'
      path = 'icons/running.png'
    when :grading
      title = 'Grading in progress'
      path = 'icons/waiting.png'
    when :graded
      title = 'Grades'
      path = 'icons/grades.png'
    else
      raise "Unknown state ${state}"
    end
    image_tag path, alt: title, title: title, class: 'ui-icon'
  end

  # Icon representing an analysis' status property.
  def analysis_status_icon_tag(analysis)
    title = analysis_status_text analysis
    status = analysis ? analysis.status : :no_analyzer

    path = case status
    when :no_analyzer
      'icons/draft.png'
    when :queued
      'icons/waiting.png'
    when :running
      'icons/running.png'
    when :limit_exceeded
      'icons/timer.png'
    when :crashed
      'icons/error.png'
    when :wrong
      'icons/error.png'
    when :ok
      'icons/checkmark.png'
    end
    image_tag path, alt: title, title: title, class: 'ui-icon'
  end

  def deadline_state_icon_tag(state = :pending)
    case state
    when :pending
      title = 'Pending deadline'
      path = 'icons/deadline.png'
    when :missed
      title = 'Missed deadline'
      path = 'icons/deadline_missed.png'
    when :overdue
      title = 'Overdue'
      path = 'icons/deadline_overdue.png'
    when :changing
      title = 'Processing'
      path = 'icons/waiting.png'
    when :rejected
      title = 'Rejected submission'
      path = 'icons/error.png'
    when :done
      title = 'Done'
      path = 'icons/checkmark.png'
    end
    image_tag path, alt: title, title: title, class: 'ui-icon'
  end

  # Show this icon next to forms that configure site features.
  def config_icon_tag
    image_tag 'icons/config.png', alt: 'Configuration', class: 'ui-icon'
  end

  # Shown on buttons for chronologically ordered lists of events.
  def feed_icon_tag
    image_tag 'icons/feed.png', alt: 'Change history', class: 'ui-icon'
  end

  # Show this icon next to submission-related functionality.
  def homework_icon_tag
    image_tag 'icons/homework.png', alt: 'Homework', class: 'ui-icon'
  end

  # Show this icon next to grading-related functionality.
  def grades_icon_tag
    image_tag 'icons/grades.png', alt: 'Grades', class: 'ui-icon'
  end

  # Show this icon next to links that lead to displaying contact information.
  def contacts_icon_tag
    image_tag 'icons/contacts.png', alt: 'Contacts', class: 'ui-icon'
  end

  # Show this icon next to links to aggregate information.
  def dashboard_icon_tag
    image_tag 'icons/dashboard.png', alt: 'Dashboard', class: 'ui-icon'
  end

  # A bunch of unrelated tools.
  def tools_icon_tag
    image_tag 'icons/tools.png', alt: 'Toolbox', class: 'ui-icon'
  end
end
