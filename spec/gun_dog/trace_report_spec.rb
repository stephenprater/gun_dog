require "spec_helper"

RSpec.describe GunDog::TraceReport do
  let(:trace) {
    GunDog.trace(Tester) do
      Tester.new.foo('a thing')
    end
  }

  let(:trace_json) {
    <<~JS.squish.gsub(/\s+/,'')
    {
      "klass": "Tester",
      "collaborating_classes": [],
      "call_records": [
        {
          "klass": "Tester",
          "method_name": "foo",
          "class_method" : false,
          "internal": false,
          "cyclical": false,
          "args": { "arg" : "String" },
          "return_value": "String"
        }
      ]
    }
    JS
  }



  describe '#to_json' do
    it 'serialize a TraceReport to JSON' do
      expect(trace.to_json.squish).to eq trace_json
    end
  end

  describe '#save' do
    before do
      FileUtils.mkdir('tmp')
    end

    after do
      FileUtils.rm_rf('tmp')
    end

    it 'writes a json file' do
      expect { trace.save('tmp/tester-trace.json') }
        .to change { File.exists?('tmp/tester-trace.json') }
        .from(false).to(true)
    end
  end

  describe '#load' do
    before do
      FileUtils.mkdir('tmp')
    end

    after do
      FileUtils.rm_rf('tmp')
    end

    it 'loads a json file into a trace' do
      trace.save('tmp/tester-trace.json')
      expect(described_class.load('tmp/tester-trace.json').to_json).to eq trace_json
    end
  end
end

