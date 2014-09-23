require 'spec_helper'

describe Api::V1::SubjectsController, type: :controller do
  let!(:workflow) { create(:workflow_with_subject_sets) }
  let!(:subject_set) { workflow.subject_sets.first }
  let!(:subjects) { create_list(:set_member_subject, 20, subject_set: subject_set) }
  let!(:user) { create(:user) }

  let(:api_resource_name) { "subjects" }

  context "logged in user" do
    before(:each) do
      default_request user_id: user.id, scopes: ["subject"]
    end

    describe "#index" do

      context "subjects that use the SubjectSerializer" do
        let(:api_resource_attributes) do
          [ "id", "metadata", "locations", "zooniverse_id", "created_at", "updated_at"]
        end
        let(:api_resource_links) { [ "subjects.owner" ] }

        context "without random sort" do
          before(:each) do
            get :index
          end

          it "should return 200" do
            expect(response.status).to eq(200)
          end

          it "should return a page of 20 objects" do
            expect(json_response[api_resource_name].length).to eq(20)
          end

          it_behaves_like "an api response"
        end
      end

      context "subjects that use the SetMemberSubjectSerializer" do
        let(:api_resource_attributes) do
          [ "id", "metadata", "locations", "zooniverse_id", "classifications_count",
           "state", "set_member_subject_id", "created_at", "updated_at" ]
        end
        let(:api_resource_links) { [ "subjects.subject_set" ] }

        context "with queued subjects" do
          let(:request_params) { { sort: 'queued', workflow_id: workflow.id.to_s } }
          let!(:ues) do
            create(:user_enqueued_subject, user: user,
                                           workflow: workflow,
                                           subject_ids: subjects.map(&:id))
          end

          before(:each) do
            get :index, request_params
          end

          it "should return 200" do
            get :index, request_params
            expect(response.status).to eq(200)
          end

          it 'should return a page of 10 objects' do
            get :index, request_params
            expect(json_response[api_resource_name].length).to eq(10)
          end

          it_behaves_like "an api response"
        end

        context "with subject_set_ids" do
          let(:request_params) { { subject_set_id: subject_set.id.to_s } }

          before(:each) do
            get :index, request_params
          end

          it "should return 200" do
            get :index, request_params
            expect(response.status).to eq(200)
          end

          it 'should return a page of 10 objects' do
            get :index, request_params
            expect(json_response[api_resource_name].length).to eq(20)
          end

          it_behaves_like "an api response"
        end

        context "with random sort" do
          let(:request_params) { { sort: 'random', workflow_id: workflow.id.to_s } }
          let(:cellect_results) { cellect_results = subjects.take(10).map(&:id) }
          let!(:session) do
            request.session = { cellect_hosts: { workflow.id.to_s => 'example.com' } }
          end

          describe "testing the response" do

            before(:each) do
              allow(stubbed_cellect_connection).to receive(:get_subjects).and_return(cellect_results)
              get :index, request_params
            end

            it "should return 200" do
              get :index, request_params
              expect(response.status).to eq(200)
            end

            it 'should return a page of 10 objects' do
              get :index, request_params
              expect(json_response[api_resource_name].length).to eq(10)
            end

            it_behaves_like "an api response"
          end

          describe "testing the cellect client setup" do

            it 'should make a request against Cellect' do
              expect(stubbed_cellect_connection).to receive(:get_subjects).and_return(cellect_results)
              get :index, request_params
            end
          end
        end
      end
    end
  end
end
