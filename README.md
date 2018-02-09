Automated Tooling
====================
Utilities using octokit to help find user defined code.

More to come...

Github Setup
--------------

For authentication, follow the steps here to get your OAth token generated: https://help.github.com/articles/creating-an-access-token-for-command-line-use . The default scope options are fine.
You can set your Github OAuth token in the `GITHUB_COMMUNITY_TOKEN` environment variable instead of using the `-t` option.

Initial Setup
--------------

Install required libraries: eg

  To install in local lib dir /usr/local/lib/ruby/gems/:

    'bundle install'

  To install in designated path:

    'bundle install --path .bundle/gems/'

An Example Run
---------------

An example for running search_code on all available user repos:

  With GITHUB_COMMUNITY_TOKEN environment variable set:

    'bundle exec ruby ./search_code.rb -s artifactory --puppetlabs'

  Without GITHUB_COMMUNITY_TOKEN environment variable set:

    'bundle exec ruby ./search_code.rb -s artifactory --puppetlabs -t (ACCESS TOKEN HERE)'

Pull Requests
--------------

Display pull requests on modules in a github organisation, filtered by various
criteria. Use the `--help` flag to see all parameters.

https://github.com/jennaesq/automated-tooling/pulls
