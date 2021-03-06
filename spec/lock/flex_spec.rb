require "spec_helper"

describe "the lockfile format" do
  it "generates a simple lockfile for a single source, gem" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack"
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        rack

      specs:
        rack (1.0.0)
    G
  end

  it "generates a simple lockfile for a single source, gem with dependencies" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama"
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        rack-obama

      specs:
        rack (1.0.0)
        rack-obama (1.0):
          rack
    G
  end

  def be_with_diff(expected)
    # Trim the leading spaces
    spaces = expected[/\A\s+/, 0] || ""
    expected.gsub!(/^#{spaces}/, '')

    simple_matcher "should be" do |given, m|
      m.failure_message = "The lockfile did not match what you expected:\n===============\n" << Differ.diff_by_line(expected, given).to_s << "\n===============\n"
      expected == given
    end
  end

  def lockfile_should_be(expected)
    lock = File.read(bundled_app("Gemfile.lock"))
    lock.should be_with_diff(expected)
  end

  it "generates a simple lockfile for a single source, gem with a version requirement" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama", ">= 1.0"
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        rack-obama (>= 1.0)

      specs:
        rack (1.0.0)
        rack-obama (1.0):
          rack
    G
  end

  it "generates a simple lockfile for a single pinned source, gem with a version requirement" do
    git = build_git "foo"

    flex_install_gemfile <<-G
      gem "foo", :git => "#{lib_path("foo-1.0")}"
    G

    lockfile_should_be <<-G
      dependencies:
        foo:
          git: #{lib_path("foo-1.0")} ref:"#{git.ref_for('master', 6)}"

      specs:
        foo (1.0)
    G
  end

  it "serializes global git sources" do
    git = build_git "foo"

    flex_install_gemfile <<-G
      git "#{lib_path('foo-1.0')}"
      gem "foo"
    G

    lockfile_should_be <<-G
      sources:
        git: #{lib_path('foo-1.0')} ref:"#{git.ref_for('master', 6)}"

      dependencies:
        foo

      specs:
        foo (1.0)
    G
  end

  it "generates a lockfile with a ref for a single pinned source, git gem with a branch requirement" do
    git = build_git "foo"
    update_git "foo", :branch => "omg"

    flex_install_gemfile <<-G
      gem "foo", :git => "#{lib_path("foo-1.0")}", :branch => "omg"
    G

    lockfile_should_be <<-G
      dependencies:
        foo:
          git: #{lib_path("foo-1.0")} ref:"#{git.ref_for('omg', 6)}"

      specs:
        foo (1.0)
    G
  end

  it "generates a lockfile with a ref for a single pinned source, git gem with a tag requirement" do
    git = build_git "foo"
    update_git "foo", :tag => "omg"

    flex_install_gemfile <<-G
      gem "foo", :git => "#{lib_path("foo-1.0")}", :tag => "omg"
    G

    lockfile_should_be <<-G
      dependencies:
        foo:
          git: #{lib_path("foo-1.0")} ref:"#{git.ref_for('omg', 6)}"

      specs:
        foo (1.0)
    G
  end

  it "serializes pinned path sources to the lockfile" do
    build_lib "foo"

    flex_install_gemfile <<-G
      gem "foo", :path => "#{lib_path("foo-1.0")}"
    G

    lockfile_should_be <<-G
      dependencies:
        foo:
          path: #{lib_path("foo-1.0")}

      specs:
        foo (1.0)
    G
  end

  it "lists gems alphabetically" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "thin"
      gem "actionpack"
      gem "rack-obama"
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        actionpack
        rack-obama
        thin

      specs:
        actionpack (2.3.2):
          activesupport (= 2.3.2)
        activesupport (2.3.2)
        rack (1.0.0)
        rack-obama (1.0):
          rack
        thin (1.0):
          rack
    G
  end

  it "order dependencies of dependencies in alphabetical order" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rails"
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        rails

      specs:
        actionmailer (2.3.2):
          activesupport (= 2.3.2)
        actionpack (2.3.2):
          activesupport (= 2.3.2)
        activerecord (2.3.2):
          activesupport (= 2.3.2)
        activeresource (2.3.2):
          activesupport (= 2.3.2)
        activesupport (2.3.2)
        rails (2.3.2):
          actionmailer (= 2.3.2)
          actionpack (= 2.3.2)
          activerecord (= 2.3.2)
          activeresource (= 2.3.2)
          rake
        rake (0.8.7)
    G
  end

  it "does not add the :require option to the lockfile" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama", ">= 1.0", :require => "rack/obama"
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        rack-obama (>= 1.0)

      specs:
        rack (1.0.0)
        rack-obama (1.0):
          rack
    G
  end

  it "does not add the :group option to the lockfile" do
    flex_install_gemfile <<-G
      source "file://#{gem_repo1}"

      gem "rack-obama", ">= 1.0", :group => :test
    G

    lockfile_should_be <<-G
      sources:
        gem: file:#{gem_repo1}/

      dependencies:
        rack-obama (>= 1.0)

      specs:
        rack (1.0.0)
        rack-obama (1.0):
          rack
    G
  end
end