# encoding: utf-8

require File.expand_path('../../lib/git-patch-patch.rb', __FILE__)

RSpec.configure do |config|
  # config from --init
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

class TestRepo

  def initialize
    @t = Git::Trifle.new init: '/tmp/spec/git-patch-patch/repo'
    File.open(File.join(@t.directory, 'init'), 'w') do |f|
      f.write 'initialise'
    end
    @t.add 'init'
    @t.commit 'add init'

    basenames = %w|README FEELME|

    basenames.each do |name|
      File.open(File.join(@t.directory, "#{name}.md"), 'w') do |f|
        f.write "# #{name}.md\n# git-patch-patch\n"
      end
    end
    @t.add '.'
    @t.commit "add files"

    File.truncate File.join(@t.directory, 'init'), 0
    @t.add '.'
    @t.commit "truncate init"

    FileUtils.mkdir_p File.join(@t.directory, 'git-patch')

    basenames.each do |name|
      File.open(File.join(@t.directory, 'git-patch', "#{name}.md"), 'w') do |f|
        f.write "# #{name}.md\n# git-patch-patch\n"
      end
      @t.add '.'
      @t.commit "add file in sub dir"
    end
  end

  def directory
    @t.directory
  end

  def checkout(*args)
    @t.checkout *args
  end

  def diff
    @t.diff @t.commits[0], @t.commits[1]
  end

end
