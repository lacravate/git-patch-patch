# git patch patch

git-patch-patch is an attempt a making a not-too-bright not-too-stupid script
to review Git commit history.

Using it, you could, for instance, have the ground matter to make a real
`git-mv` with history.

## Installation

Ruby 1.9.2 is required.

It is packaged as a gem, so :

Install it with rubygems:

    gem install git-patch-patch

With bundler, add it to your `Gemfile`:

``` ruby
gem "git-patch-patch"
```

## Use

### Script

``` shell
ruby bin/git-patch-patch --repo /home/me/my_repo \
     --pattern pattern_to_replce --replacement replacement \
     --patch_dir '/tmp' --branch master --patch_patch

```

I hope most of the options will be crystal clear without explanation. Yet :
 - patch dir is temp' directory where work files (patches) will be stored
 - patch_patch asks the script to perform replacement not only on filenames

It works on a dedicated branch with a barbaric name, trying the script should
be completely harmful, if not useful.

### Home-made fitting lib's

The script relies on two classes, a controller that manages some sort of
workflow, and a model attempting to represent the patch shrewdly.

I am not going to document this any further though.

If you have the kind of need falling in the scope of the script, you should be,
by far, able to modify the script, and understand what the underlying lib's are
doing.

## Use ?

Well, here's what the script does :
 - creates a specific work branch
 - iterates over all the commits of the designated branch
 - apply pattern replacement on patch file
   - only on filenames (default and pretty safe, and conflict-proof)
   - on patch content if asked
 - apply patch to working directory reusing the commit information (date,
   author, message), hence creating a new sha
 - let's you review the patch if not only on filenames 
   (patch edition through `vim`)
 - let's you review the patch if an error on patch application occurred

In the end, you have a whole new set of commits, keeping track of the project
history, integrating the changes you want to see in your file tree or file
contents.

So, if all that's of any help to you, yeah, use it.

It's safe, because it's Git (rollback should be easy), and because it's
operating on its own branch (revert being then a childlike
`git branch -D work_branch`). And there's a ludicrous amount of spec's to ensure
the script does what it says it does.


Copyright
---------

I was tempted by the WTFPL, but i have to take time to read it.
So far see LICENSE.
