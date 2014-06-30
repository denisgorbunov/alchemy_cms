module Alchemy
  module Page::PageNatures

    extend ActiveSupport::Concern

    def taggable?
      definition['taggable'] == true
    end

    def rootpage?
      !new_record? && parent_id.blank?
    end

    def systempage?
      return false
      # TODO refactor systempages
      # return true if Page.root.nil?
      # rootpage? || (parent_id == Page.root.id && !language_root?)
    end

    def folded?(user_id)
      return unless Alchemy.user_class < ActiveRecord::Base
      folded_pages.where(user_id: user_id, folded: true).any?
    end

    def contains_feed?
      definition["feed"]
    end

    # Returns true or false if the pages definition for config/alchemy/page_layouts.yml contains redirects_to_external: true
    def redirects_to_external?
      !!definition["redirects_to_external"]
    end

    def has_controller?
      !PageLayout.get(page_layout).nil? && !PageLayout.get(page_layout)["controller"].blank?
    end

    def controller_and_action
      if has_controller?
        {
          controller: definition["controller"].gsub(/(^\b)/, "/#{$1}"),
          action: definition["action"]
        }
      end
    end

    # Returns a Hash describing the status of the Page.
    #
    def status
      {
        public: public?,
        visible: visible?,
        locked: locked?,
        restricted: restricted?
      }
    end

    # Returns the translated status for given status type.
    #
    # @param [Symbol] status_type
    #
    def status_title(status_type)
      I18n.t(status[status_type].to_s, scope: "page_states.#{status_type}")
    end

    # Returns the self#page_layout definition from config/alchemy/page_layouts.yml file.
    def definition
      return {} if systempage?
      definition = PageLayout.get(page_layout)
      if definition.nil?
        log_warning "Page definition for `#{page_layout}` not found. Please check `page_layouts.yml` file."
        return {}
      end
      definition
    end

    # Returns translated name of the pages page_layout value.
    # Page layout names are defined inside the config/alchemy/page_layouts.yml file.
    # Translate the name in your config/locales language yml file.
    def layout_display_name
      I18n.t(page_layout, scope: 'page_layout_names')
    end

    # Returns the name for the layout partial
    #
    def layout_partial_name
      page_layout.parameterize.underscore
    end

    # Returns the key that's taken for cache path.
    #
    # Uses the +published_at+ value that's updated when the user publishes the page.
    #
    # If the page is the current preview it uses the updated_at value as cache key.
    #
    def cache_key
      if Page.current_preview == self
        "alchemy/pages/#{id}-#{updated_at}"
      else
        "alchemy/pages/#{id}-#{published_at}"
      end
    end

    # We use the published_at value for the cache_key.
    #
    # If no published_at value is set yet, i.e. because it was never published,
    # we return the updated_at value.
    #
    def published_at
      read_attribute(:published_at) || updated_at
    end

  end
end
