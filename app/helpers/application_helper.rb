module ApplicationHelper
  def time_delta(dtime, ref_time = Time.current)
    ((dtime < ref_time) ? "%s ago" : "in %s") %
        distance_of_time_in_words(dtime, ref_time, include_seconds: true)
  end

  # A large, wide button with the given text, Foundation-formatted.
  def submit_button_tag(&block)
    content_tag :div, class: 'row collapse align-center' do
      content_tag :div, class: 'small-9 columns' do
        button_tag type: :submit, class: 'large hollow expanded button', &block
      end
    end
  end

  # Descriptive text that reflects the boolean state of a model attribute.
  #
  # @param [Boolean] boolean_value the attribute's value
  # @param [Symbol] only optionally specify if the output should contain only an
  #   icon (:icon) or only text (:text)
  # @return [ActiveSupport::SafeBuffer] a <span> tag with descriptive text that
  #   is positive for truthy attribute values, and negative otherwise
  def boolean_description_tag(boolean_value, only: nil)
    if boolean_value
      icon = (only == :text) ? '' : true_icon_tag
      text = (only == :icon) ? '' : ' Yes'
      klass = 'true-setting'
    else
      icon = (only == :text) ? '' : false_icon_tag
      text = (only == :icon) ? '' : ' No'
      klass = 'false-setting'
    end
    content_tag :span, class: klass do
      icon + text
    end
  end

  # The flex-grid styling class to apply to the main <section>.
  def main_section_width_class
    content_for?(:sidebar) ? 'small-7' : 'small-10'
  end

  # Create a form that is formatted in Foundation syntax.
  def foundation_form_for(record, options = {}, &block)
    options[:builder] = FoundationFormBuilder
    form_for record, options, &block
  end
end
