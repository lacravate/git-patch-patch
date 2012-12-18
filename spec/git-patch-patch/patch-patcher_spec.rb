# encoding: utf-8	

require 'spec_helper'

describe 'git-patch-patch' do
  let(:test_repo) { TestRepo.new }
  let(:test_diff) { test_repo.diff }

  before(:all) {
    FileUtils.rm_rf '/tmp/spec/git-patch-patch/'
    FileUtils.mkdir_p '/tmp/spec/git-patch-patch/patches'
    test_repo
  }

  describe Git::Trifle::PatchPatcher do

    subject { described_class.new repo: '/tmp/spec/git-patch-patch/repo', patch_dir: '/tmp/spec/git-patch-patch/patches' }

    let(:commits) { subject.commits(branch: 'master')[0..1] }

    before {
      test_repo.checkout 'master'
    }

    describe 'diff and patch' do
      it "should be able to retrieve the current patch" do
        subject.diff *commits

        # chomp to cope with fuzzy behaviour i don't know (er... want)
        # how to track down any further
        # the diff that happens sometimes is on the presence or absence
        # of a trailing line break. It's harmless anyhow.
        subject.patch.chomp.should == test_diff.chomp
      end
    end

    describe 'commit_patch' do
      before {
        subject.checkout '__with_history', commit: commits.first
        subject.diff *commits
        subject.patch.save
        subject.commit_patch
      }

      it "should be able to apply a patch, add the files with status, and create a commit" do
        File.read('/tmp/spec/git-patch-patch/repo/README.md').should == "# README.md\n# git-patch-patch\n"
        subject.commits.size.should == 2
      end
    end

    describe 'patch_work' do
      context 'when job is done' do
        before {
          subject.diff *commits
          subject.patch.save
        }

        it "should nicely handle a Git failure and giving a chance to do things properly" do
          errors = []
          works = []

          subject.patch_work('git-patch', 'plop', :patch, :filenames) do |patch|
            errors << patch.error
            works << patch.work
          end

          errors.compact.size.should == 0
          works.size.should == 7
          works.first.should == :done
        end
      end

      context 'replacement of "init"' do
        it "should nicely handle a Git failure and giving a chance to do things properly" do
          errors = []
          works = []

          subject.patch_work('initialise', 'plopinette', :patch) do |patch|
            errors << patch.error
            works << patch.work

            if patch.error
              patch.gsub! 'plopinette', 'initialise'
            end
          end

          File.size(File.join(test_repo.directory, 'init')).should == 0
          errors.compact.size.should == 1
          works.size.should == subject.commits.size
        end
      end

      context 'replacement of "git-patch"' do
        it "should move files to git-patch-patch subdir, replace the pattern in files and report no error" do
          errors = []
          works = []

          subject.patch_work('git-patch', 'plop', :patch, :filenames) do |patch|
            errors << patch.error
            works << patch.work

            patch.error.should be_nil
          end

          File.exists?(File.join(test_repo.directory, 'plop')).should be_true
          File.exists?(File.join(test_repo.directory, 'git-patch')).should be_false
          File.read(File.join(test_repo.directory, 'README.md')).include?('plop-patch').should be_true
          errors.compact.size.should == 0
          works.size.should == 8
        end

        it "should move files to git-patch-patch only in filenames subdir and report no error" do
          errors = []
          works = []

          subject.patch_work('git-patch', 'plap', :filenames) do |patch|
            errors << patch.error
            works << patch.work

            patch.error.should be_nil
          end

          File.exists?(File.join(test_repo.directory, 'plap')).should be_true
          File.exists?(File.join(test_repo.directory, 'git-patch')).should be_false
          File.read(File.join(test_repo.directory, 'README.md')).include?('plop-patch').should be_false
          errors.compact.size.should == 0
          works.size.should == 4
        end

        it "should operate normally even though no patch was patched" do
          errors = []
          works = []

          subject.patch_work('git-potch', 'plap', :filenames, :patch) do |patch|
            errors << patch.error
            works << patch.work

            patch.work.should == :nothing
            patch.error.should be_nil
          end

          errors.compact.size.should == 0
          works.size.should == 8
        end
      end

    end

  end

  describe Git::Trifle::PatchPatch do
    subject { described_class.new test_diff, file: '/tmp/spec/git-patch-patch/patches/patch-patch-spec' }

    describe 'filenames' do

      it "should be able to patch filenames only" do
        subject.patch_filenames("ME", 'YOU').should be_true
        subject.should == test_diff.
          gsub('a/README.md', 'a/READYOU.md').
          gsub('b/README.md', 'b/READYOU.md').
          gsub('a/FEELME.md', 'a/FEELYOU.md').
          gsub('b/FEELME.md', 'b/FEELYOU.md')
      end

      it "should be able to patch filenames only" do
        subject.patch_filenames("README.md", 'TRASHME.md').should be_true
        subject.should == test_diff.
          gsub('a/README.md', 'a/TRASHME.md').
          gsub('b/README.md', 'b/TRASHME.md')
      end
    end

    describe 'patch_patch' do
      before {
        subject.patch_filenames("README.md", 'TRASHME.md')
      }

      it "does the job and report true" do
        subject.patch_patch("README.md", 'TRASHME.md').should be_true
        subject.should == test_diff.
          gsub('README.md', 'TRASHME.md')
      end

      it "should be able to patch patch body" do
        subject.patch_patch("plop", 'plap').should be_false
        subject.should == test_diff.
          gsub('a/README.md', 'a/TRASHME.md').
          gsub('b/README.md', 'b/TRASHME.md')
      end
    end

    describe 'save' do
      before {
        subject.save
      }

      it "should be able to save patch to a file" do
        File.exists?(subject.file).should be_true
        File.read(subject.file).should == test_diff << "\n"
      end
    end

    describe 'load_from_file' do
      before {
        subject.file.save "heehaa\ngiddyup\n"
        subject.reload_from_file
      }

      it "should reload patch content from its attached file" do
        File.exists?(subject.file).should be_true
        subject.file.read.should == subject
        subject.changed?.should be_true
      end
    end

  end

  after {
    FileUtils.rm_rf '/tmp/spec/git-patch-patch/patches'
    FileUtils.mkdir_p '/tmp/spec/git-patch-patch/patches'
  }

  after(:all) {
    FileUtils.rm_rf '/tmp/spec/git-patch-patch'
  }
end
