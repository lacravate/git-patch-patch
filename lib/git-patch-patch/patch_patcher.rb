# encoding: utf-8

# from stdlib
require 'pathname'
require 'forwardable'

# from me
require 'git-trifle'
require 'path-accessor'

# this class knows how make a diff and
# write it to a retrievable patch
# how to apply a patch and commit it
module Git

  class Trifle

    # not too bright though
    class PatchPatcher

      # clean API best bud
      extend Forwardable

      # what we'll use from git-trifle
      def_delegators :@t, :commits, :clone, :checkout

      # current patch generated by the last diff performed
      attr_reader :patch

      # open the repo in path
      # set the root path from where the patches are retrieved
      def initialize(options)
        options = {branch: 'master', patch_dir: '/tmp'}.merge options

        # git handler
        @t = Git::Trifle.new options[:repo]
        # where the patch file will be stored
        @patch_dir = Pathstring.new options[:patch_dir]
        # branch from which the commits will be reviewed
        @branch = options[:branch]
        # list of reviewed commits
        @patcher_commits = commits branch: @branch
      end

      def patch_work(pattern, replacement, *options, &block)
        # work branch
        checkout_work_branch

        # main workflow
        @patcher_commits.each_with_index do |c, id|
          # exit on the last commit
          break unless c_next = @patcher_commits[id + 1]

          # current diff sets the current patch
          diff c, c_next

          # even if work is done we yield the patch
          # to allow modification
          # if a patch file is found, we commit and
          # jump to next iteration
          patch.work == :done &&
            yield(patch) &&
            patch_file_for?(c_next) &&
            commit_patch(&block) &&
            next

          # patch filenames and / or patch content
          options.each do |work|
            patch.send "patch_#{work}", pattern, replacement
            yield patch
          end

          # save to file and commit
          patch.save
          commit_patch &block
        end
      end

      # this class base operation
      # a diff between two sha's stored in @patch
      def diff(first_commit, second_commit)
        @patch = PatchPatch.new @t.diff(first_commit, second_commit),
                                first_commit: first_commit,
                                second_commit: second_commit,
                                file: patch_file_for(second_commit),
                                work: patch_file_for?(second_commit)
      end

      # plain as plain :
      # - patch from file
      # - apply and commit with a reuse of the commit message
      #   from the second sha of the diff which generated the patch
      def commit_patch
        patch.error = nil

        @t.apply patch.file
        @t.add '.'
        @t.commit '', reuse_message: patch.second_commit
      rescue => error
        # Houston we have a problem
        patch.error = error
        # first we yield to allow a fix
        yield patch if block_given?

        # if a fix was made, retry
        if patch.changed?
          patch.save
          retry
        end
      end

      def checkout_work_branch
        # checkout -b barbaric_name sha
        checkout "__patch_patcher_#{Time.now.to_f}", commit: @patcher_commits.first
      end

      # unique patch filename for a given sha and a given local repo'
      def patch_file_for(commit)
        @patch_dir.join 'git-patch-patch',
                         # horrendous but necessary to ensure unicity
                         # of path, without having an absolute path
                         # that 'join' doesn't like
                         Pathname(@t.directory).realpath.to_s.sub('/',''),
                         commit.to_s,
                         'patch'
      end

      # is there a patch for this sha ?
      def patch_file_for?(commit)
        patch_file_for(commit).exist?
      end

    end

    # patch model as a String for its primary
    # interface, but it knows a lot more
    class PatchPatch < String

      # file handling
      extend PathAccessor

      path_accessor :file
      attr_accessor :first_commit, :second_commit, :work, :error

      # quick list of Strings methods that perform in-place
      # modification
      # we install a simple shunt on these methods to implement
      # the changed? method

      # :!= is left here by design to have changed? answer true
      # the first time it is called after a possible change
      instance_methods.grep(/\!/).push(:<<).each do |meth|
        define_method meth do |*args, &block|
          # record previous state
          @previous = self.to_s
          # call to vanilla
          super *args, &block
        end
      end

      # defines patch_patch and patch_filenames
      %w|filenames patch|.each do |work|
        define_method "patch_#{work}".to_sym do |pattern, replacement|
          # the actual job on patch
          send work.to_sym, pattern, replacement

          # changed to avoid messing with changed? the user
          # could call
          changed = self.to_s != @previous.to_s
          @work = changed ? work.to_sym : :nothing
          changed # return value says if it did anything
        end
      end

      def initialize(string, attributes=nil)
        # instance attributes in one line
        (attributes ||= {}).each { |k, v| send "#{k}=", v }
        # give work the value we want
        @work = :done if @work == true
        # changes handler
        @previous = string.to_s

        # vanilla
        super string
      end

      def changed?
        self != @previous
      end

      # to file
      def save
        # trailing \n or git complains
        file.save!(self + "\n")
      end

      # patch content from file
      def reload_from_file
        @previous = self.to_s
        replace file.read
      end

      private

      # naughty nasty operation on filenames in patch
      def filenames(pattern, replacement)
        # we trap what begins with a:/ or b/ until we find the pattern
        # it's replaced by what's captured with replacement appended
        gsub! /(a|b)\/([^\n]*?)#{pattern}/, "\\1/\\2#{replacement}"
      end

      # Now this not pretty : we allow ourselves to alter anything
      # in the patch according to pattern/replacement couple.
      # Welcome conflictorama
      def patch(pattern, replacement)
        gsub! pattern, replacement
      end

    end

  end

end