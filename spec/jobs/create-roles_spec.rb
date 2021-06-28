require 'rspec'
require 'yaml'
require 'json'
require 'bosh/template/test'

describe 'create-roles job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('create-roles') }

  describe 'run.sh.erb' do
    let(:template) { job.template('bin/run') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'kibana',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'kibana'=> {
              'port' => '5601',
              'elasticsearch' => {
                'client' => {
                  'username' => 'admin',
                  'password' => 'password',
                  'protocol' => 'http'
              }
            }
          }
        }
        )
      ] }

    describe 'providing a roles' do
      let(:valid_role) {
        YAML.load(%q(
        - endpoint: /api/security/role/monitoring-role
          action: PUT
          headers:
            - Content-Type: application/json
            - kbn-xsrf: true
          payload: |
            {
              "elasticsearch": {
                "cluster": [],
                "indices": [
                  {
                    "names": [ "*" ],
                    "privileges": [ "all" ]
                  }
                ]
              },
              "kibana": [
                {
                  "base": [],
                  "feature": {
                    "visualize": ["all"],
                    "dashboard": ["all"],
                    "discover": ["all"]
                  },
                  "spaces": ["*"]
                }
              ]
            }
        ))
      }

      let(:valid_rendered_request) {
        "curl -s -k -X  PUT -H 'Content-Type: application/json' -H 'kbn-xsrf: true'  http://admin:password@10.0.8.2:5601/api/security/role/monitoring-role"
      }

      it 'renders properly' do
        expect { template.render({"roles" => valid_role}, consumes: links) }.not_to raise_error
        rendered_template = template.render({"roles" => valid_role}, consumes: links)
        
        expect(rendered_template).to include(valid_rendered_request)
        puts rendered_template
      end
    end
  end
end