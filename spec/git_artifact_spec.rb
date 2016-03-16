require_relative 'spec_helper'

describe Dapp::GitArtifact do
  before :all do
    shellout 'git config -l | grep "user.email" || git config --global user.email "dapp@flant.com"'
    shellout 'git config -l | grep "user.name" || git config --global user.name "Dapp Dapp"'
  end

  before :each do
    @builder = instance_double('Dapp::Builder')
    allow(@builder).to receive(:register_atomizer)
    allow(@builder).to receive(:build_path) do |*args|
      File.absolute_path(File.join(*args))
    end
    allow(@builder).to receive(:home_path).and_return('')
    allow(@builder).to receive(:shellout) do |*args, **kwargs|
      shellout(*args, **kwargs)
    end
    allow(@builder).to receive(:filelock).and_yield

    @docker = instance_double('Dapp::Docker')
    allow(@docker).to receive(:add_artifact)
    allow(@docker).to receive(:run)
    allow(@builder).to receive(:docker).and_return(@docker)

    @repo = Dapp::GitRepo::Chronicler.new(@builder, 'repo')
  end

  def reset_instances
    RSpec::Mocks.space.proxy_for(@builder).send(:instance_variable_get, :@messages_received).clear
    RSpec::Mocks.space.proxy_for(@docker).send(:instance_variable_get, :@messages_received).clear
  end

  # TODO: branch: 'master'
  # TODO: cwd: nil
  # TODO: paths: nil

  def commit(changefile, changedata, branch: 'master')
    shellout "cd repo; git checkout #{branch}"
    changefile = File.join('repo', changefile)
    FileUtils.mkdir_p File.split(changefile)[0]
    File.write changefile, changedata
    @repo.commit!
  end

  def artifact_init(where_to_add, id: nil, changefile: 'data.txt', changedata: random_string, **kwargs)
    commit(changefile, changedata)

    (@artifact ||= {})[id] = Dapp::GitArtifact.new(@builder, @repo, where_to_add, **kwargs)
  end

  def artifact_reset(id: nil)
    @artifact.delete(id).send(:atomizer).tap do |atomizer|
      atomizer.commit!
      atomizer.send(:instance_variable_get, :@file).close
    end
  end

  def artifact_filename(ending, id: nil)
    "#{@artifact[id].send(:repo).name}#{@artifact[id].send(:name) ? "_#{@artifact[id].send(:name)}" : nil}.#{@artifact[id].send(:branch)}#{ending}"
  end

  def tar_files_owners(arhive)
    shellout("tar -tvf #{arhive}").stdout.lines.map { |s| s.strip.sub(%r(.{11}([^\/]+)\/.*), '\1') }.uniq
  end

  def tar_files_groups(arhive)
    shellout("tar -tvf #{arhive}").stdout.lines.map { |s| s.strip.sub(%r(.{11}[^\/]+\/([^\s]+).*), '\1') }.uniq
  end

  # rubocop:disable Metrics/AbcSize
  def artifact_archive(id: nil)
    reset_instances
    @artifact[id].add_multilayer!

    expect(@docker).to have_received(:add_artifact).with(
      %r{\/#{artifact_filename('.tar.gz', id: id)}$},
      artifact_filename('.tar.gz', id: id),
      @artifact[id].send(:where_to_add),
      step: :prepare
    )
    expect(File.read(artifact_filename('.commit', id: id)).strip).to eq(@repo.latest_commit)
    expect(File.exist?(artifact_filename('.tar.gz', id: id))).to be_truthy

    [:owner, :group].each do |subj|
      expect(send(:"tar_files_#{subj}s", artifact_filename('.tar.gz', id: id))).to eq([@artifact[id].send(subj).to_s]) if @artifact[id].send(subj)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def random_string
    (('a'..'z').to_a * 10).sample(100).join
  end

  def artifact_latest_patch(id: nil, **kwargs)
    artifact_patch(
      '_latest',
      :setup,
      id: id,
      **kwargs
    )
  end

  def artifact_layer_patch(layer, id: nil, **kwargs)
    Timecop.travel(Time.now + @artifact[id].send(:interlayer_period))

    artifact_patch(
      format('_layer_%04d', layer),
      :build,
      id: id,
      **kwargs
    )
  ensure
    Timecop.return
  end

  # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists, Metrics/MethodLength
  def artifact_patch(suffix, step, id:, changefile: 'data.txt', changedata: random_string, should_be_empty: false)
    commit(changefile, changedata)

    reset_instances
    @artifact[id].add_multilayer!

    patch_filename = artifact_filename("#{suffix}.patch.gz", id: id)
    patch_filename_esc = Regexp.escape(patch_filename)
    commit_filename = artifact_filename("#{suffix}.commit", id: id)

    if should_be_empty
      expect(@docker).to_not have_received(:add_artifact).with(/#{patch_filename_esc}$/, patch_filename, '/tmp', step: step)
      expect(@docker).to_not have_received(:run).with(/#{patch_filename_esc}/, /#{patch_filename_esc}$/, step: step)
      expect(File.exist?(patch_filename)).to be_falsy
      expect(File.exist?(commit_filename)).to be_falsy
    else
      expect(@docker).to have_received(:add_artifact).with(/#{patch_filename_esc}$/, patch_filename, '/tmp', step: step)
      expect(@docker).to have_received(:run).with(
        %r{^zcat \/tmp\/#{patch_filename_esc} \| .*git apply --whitespace=nowarn --directory=#{@artifact[id].send(:where_to_add)}$},
        "rm /tmp/#{patch_filename}",
        step: step
      )
      { owner: 'u', group: 'g' }.each do |subj, flag|
        if @artifact[id].send(subj)
          expect(@docker).to have_received(:run).with(/#{patch_filename_esc} \| sudo.*-#{flag} #{@artifact[id].send(subj)}.*git apply/, any_args)
        end
      end
      expect(File.read(commit_filename).strip).to eq(@repo.latest_commit)
      expect(File.exist?(patch_filename)).to be_truthy
      expect(File.exist?(commit_filename)).to be_truthy
      expect(shellout("zcat #{patch_filename}").stdout).to match(/#{changedata}/)
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/ParameterLists, Metrics/MethodLength

  def artifact_do_test(where_to_add, latest_patch: true, layers: 3, **kwargs)
    artifact_init where_to_add, **kwargs
    artifact_archive
    layers.times do |i|
      artifact_layer_patch i + 1
    end
    artifact_latest_patch if latest_patch
  end

  def artifact_expect_clean(id: nil)
    expect(Dir.glob(artifact_filename('{.,_}*', id: id)))
      .to match_array([artifact_filename('.paramshash', id: id), artifact_filename('.atomizer', id: id)])
  end

  it '#archive_only', test_construct: true do
    artifact_do_test '/dest', latest_patch: false, layers: 0
  end

  it '#latest_patch', test_construct: true do
    artifact_do_test '/dest', layers: 0
  end

  it '#layer_patch', test_construct: true do
    artifact_do_test '/dest', latest_patch: false, layers: 1
  end

  it '#layer_patch_and_latest_patch', test_construct: true do
    artifact_do_test '/dest', layers: 1
  end

  it '#multiple_layer_patches_and_latest_patch', test_construct: true do
    artifact_do_test '/dest'
  end

  it '#multiple_artifacts', test_construct: true do
    artifact_init '/dest', name: 'a', id: :a
    artifact_init '/dest_2', name: 'b', id: :b
    artifact_archive id: :b
    artifact_archive id: :a

    artifact_layer_patch 1, id: :a
    artifact_layer_patch 1, id: :b
    artifact_layer_patch 2, id: :b
    artifact_layer_patch 2, id: :a

    artifact_latest_patch id: :b
    artifact_latest_patch id: :a
    artifact_latest_patch id: :a
    artifact_latest_patch id: :b

    artifact_reset id: :a
    artifact_reset id: :b

    artifact_init '/dest', name: 'a', id: :a
    artifact_init '/dest_2', name: 'b', id: :b
    artifact_latest_patch id: :a
    artifact_latest_patch id: :b
  end

  it '#remove_latest_patch_if_no_more_diff', test_construct: true do
    artifact_init '/dest', changedata: 'text'
    artifact_archive
    artifact_latest_patch
    artifact_latest_patch changedata: 'text', should_be_empty: true

    3.times do |i|
      artifact_layer_patch i + 1, changedata: "text_#{i}"
      artifact_latest_patch
      artifact_latest_patch changedata: "text_#{i}", should_be_empty: true
    end
  end

  { cwd: 'x', paths: 'x', owner: 70_500, group: 70_500 }.each do |param, value|
    it "#autocleanup_on_#{param}_change", test_construct: true do
      artifact_do_test '/dest', layers: 2

      artifact_reset
      artifact_init '/dest', **{ param => value }
      artifact_expect_clean
    end
  end

  class << self
    def users_and_groups_to_test
      users = [nil, 'root', 100_500]
      users << 'some_unknown' unless shellout('lsb_release -cs').stdout.strip == 'precise'
      users.product(users)
    end
  end

  users_and_groups_to_test.each do |owner, group|
    it "#change_owner_to_#{owner}_and_group_to_#{group}", test_construct: true do
      artifact_do_test '/dest', owner: owner, group: group
    end
  end

  it '#interlayer_period', test_construct: true do
    artifact_do_test '/dest', interlayer_period: 10
  end

  it '#flush_cache', test_construct: true do
    artifact_do_test '/dest'
    artifact_reset
    artifact_init '/dest', flush_cache: true
    artifact_expect_clean
  end
end
