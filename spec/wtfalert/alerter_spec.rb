# frozen_string_literal: true

require 'tmpdir'
require 'wtfalert/alerter'

# dir = Dir.mktmpdir nil, '/tmp'
dir = '/tmp'

RSpec.describe Wtfalert::Alerter do
  let(:alerter) {
    described_class.new(
      :caller => File.basename(__FILE__),
      :level => 'debug',
      :screen => true,
      :options => { :store => dir }
    )
  }

  before :context do
    alert_store = File.join(dir,'alerts.yaml')
    File.unlink(alert_store) if File.exist?(alert_store)
  end

  it 'creates alerter' do
    expect(alerter).not_to be_nil
  end

  it 'raises and sends test alert' do
    alerter.raise_alert(:key => 'rspec.test')
    expect(alerter.status).to eq('raised: 1 cleared: 0 sent: 1 throttled: 0 errors: 0')
  end

  it 'raises and throttles test alert' do
    alerter.raise_alert(:key => 'rspec.test')
    expect(alerter.status).to eq('raised: 1 cleared: 0 sent: 0 throttled: 1 errors: 0')
  end

  it 'clears test alert' do
    alerter.clear(:key => 'rspec.test')
    expect(alerter.status).to eq('raised: 0 cleared: 1 sent: 0 throttled: 0 errors: 0')
  end
end
