require 'spec_helper'

describe MergeRequestsFinder do
  let(:user)  { create :user }
  let(:user2) { create :user }

  let(:project1) { create(:empty_project) }
  let(:project2) { create(:empty_project, forked_from_project: project1) }
  let(:project3) { create(:empty_project, :archived, forked_from_project: project1) }

  let!(:merge_request1) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project1) }
  let!(:merge_request2) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project1, state: 'closed') }
  let!(:merge_request3) { create(:merge_request, :simple, author: user, source_project: project2, target_project: project2) }
  let!(:merge_request4) { create(:merge_request, :simple, author: user, source_project: project3, target_project: project3) }

  before do
    project1.team << [user, :master]
    project2.team << [user, :developer]
    project3.team << [user, :developer]
    project2.team << [user2, :developer]
  end

  describe "#execute" do
    it 'filters by scope' do
      params = { scope: 'authored', state: 'opened' }
      merge_requests = MergeRequestsFinder.new(user, params).execute
      expect(merge_requests.size).to eq(3)
    end

    it 'filters by project' do
      params = { project_id: project1.id, scope: 'authored', state: 'opened' }
      merge_requests = MergeRequestsFinder.new(user, params).execute
      expect(merge_requests.size).to eq(1)
    end

    it 'filters by non_archived' do
      params = { non_archived: true }
      merge_requests = MergeRequestsFinder.new(user, params).execute
      expect(merge_requests.size).to eq(3)
    end
  end
end
