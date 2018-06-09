class PluginLoader
  GEM_NAME_PREFIX = /^ghedsh-/
  attr_reader :plugins

  def initialize
    @plugins = []
  end

  def load_plugins
    find_plugins
  end

  def find_plugins
    find_gems.map do |gem|
      @plugins << { name: gem.name, path: gem_path(gem.name), plugin_klass: plugin_klass_name(gem.name) }
    end

    @plugins
  end

  def find_gems
    gem_list.select { |gem| gem.name =~ GEM_NAME_PREFIX }
  end

  def gem_path(name)
    name.tr('-', '/')
  end

  def plugin_klass_name(path)
    # convert gem paths to plugin module.
    # ghedsh/firstplugin --> Ghedsh::Firstplugin
    # ghedsh/another_name --> Ghedsh::AnotherName
    path = gem_path(path)
    path.split('/').collect do |c|
      c.split('_').collect(&:capitalize).join
    end.join('::')
  end

  def gem_list
    Gem.refresh
    Gem::Specification.respond_to?(:each) ? Gem::Specification : Gem.source_index.find_name('')
  end
end
