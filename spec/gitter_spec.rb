require 'spec_helper'
require 'git'

describe Autoversion::Gitter do

  before { Git.stub(:open).with(gitter_path).and_return(repo) }

  let(:repo) { double() }

  let(:gitter_path) { File.join(File.dirname(__FILE__), 'tmp', 'gitter') }
  let(:stable_branch) { 'master' }

  subject(:gitter) do
    ::Autoversion::Gitter.new(gitter_path, {
      :actions => [:commit],
      :stable_branch => stable_branch})
  end

  shared_context 'when on "whatever" branch' do
    before do
      repo.stub(:current_branch).and_return('whatever')
    end
  end

  shared_context 'when on stable branch' do
    before do
      repo.stub(:current_branch).and_return(stable_branch)
    end
  end

  describe '#ensure_cleanliness!' do
    context 'when config actions include "commit" && #dir_is_clean? is false' do
      before do
        gitter.stub(:dir_is_clean?).and_return(false)        
      end
      it 'raises a DirtyStaging Exception' do
        expect { gitter.ensure_cleanliness! }.to(
          raise_error ::Autoversion::Gitter::DirtyStaging)
      end
    end
  end

  describe '#dir_is_clean?' do
    # Disabled for now since ruby-git does not read .gitignore files  
    it 'returns true' do
      expect(gitter.dir_is_clean?).to be_true
    end
  end

  describe '#on_stable_branch?' do
    context 'when the config stable branch differs with the current branch' do
      include_context 'when on "whatever" branch'

      it 'returns false' do
        expect(gitter.on_stable_branch?).to be_false
      end
    end

    context 'when the config stable branch equals the current branch' do
      include_context 'when on stable branch'

      it 'returns true' do
        expect(gitter.on_stable_branch?).to be_true
      end
    end
  end

  describe '#commit!' do
    let(:version) { 'v1.2.3' }
    let(:invoke) { gitter.commit! :major, version }

    context 'when cannot commit' do
      context 'when config actions do not include "commit"' do
        subject(:gitter) do
          ::Autoversion::Gitter.new(gitter_path, {
            :actions => [],
            :stable_branch => stable_branch})
        end

        it 'returns false' do
          expect(invoke).to be_false
        end
      end

      context 'when versionType == :major && #on_stable_branch? == false' do
        include_context 'when on "whatever" branch'

        it 'raises NotOnStableBranch Exception' do
          expect { invoke }.to(
            raise_error ::Autoversion::Gitter::NotOnStableBranch)
        end
      end
    end #context cannot commit

    context 'when can commit' do
      include_context 'when on stable branch'

      before do
        repo.should_receive(:add).with('.').ordered
        repo.should_receive(:commit).with(version).ordered
      end

      it 'calls #add and #commit on the repo (Git) object' do
        invoke
      end

      context 'when config actions include "tag"' do
        subject(:gitter) do
          ::Autoversion::Gitter.new(gitter_path, {
            :actions => [:commit, :tag],
            :stable_branch => stable_branch})
        end

        it 'also calls #add_tag on the repo (Git) object' do
          repo.should_receive(:add_tag).with(version).ordered
          invoke
        end
      end
    end #context can commit
  end #commit!

end

