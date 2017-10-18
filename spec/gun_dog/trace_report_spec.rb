require "spec_helper"

RSpec.describe GunDog::TraceReport do
  let(:trace) {
    GunDog.trace(Tester) do
      Tester.new.foo('a thing')
    end
  }

  let(:trace_json) {
    <<~JS.squish
    {
      "klass": "Tester",
      "collaborating_classes": [],
      "call_records": [
        {
          "klass": "Tester",
          "method_name": "foo",
          "class_method" : false,
          "generated": false,
          "internal": false,
          "cyclical": false,
          "dynamic": false,
          "args": { "arg" : "a thing" },
          "return_value": "foo"
        }
      ]
    }
    JS
  }

  #TODO Compare these JSON structures with json schema or something instead of MultiJSON load

  describe '#to_json' do
    it 'serialize a TraceReport to JSON' do
      expect(MultiJson.load(trace.to_json)).to eq MultiJson.load(trace_json)
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
      expect(MultiJson.load(described_class.load('tmp/tester-trace.json').to_json)).to eq MultiJson.load(trace_json)
    end

    context 'when the dump includes a singleton class' do

    end
  end
end

