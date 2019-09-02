# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
# declared_trivial = github.pr_title.include? "#trivial"

# Make it more obvious that a PR is a work in progress and shouldn't be merged yet
warn("PR is classed as Work in Progress") if github.pr_title.include? "[WIP]"

# Warn when there is a big PR
warn("Big PR") if git.lines_of_code > 500

# Don't let testing shortcuts get into master by accident
# fail("fdescribe left in tests") if `grep -r fdescribe specs/ `.length > 1
# fail("fit left in tests") if `grep -r fit specs/ `.length > 1

junit.parse "test_output/test.xml"
junit.show_skipped_tests = true
junit.report

swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_all_files = true
swiftlint.lint_files

xcov.report(
   scheme: 'MDictParser-Example',
   workspace: 'Example/MDictParser.xcworkspace',
#    exclude_targets: 'Demo.app',
#    minimum_coverage_percentage: 90
)