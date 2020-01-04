# frozen_string_literal: true

RSpec.describe Wtfalert do
  it 'has a version number' do
    expect(Wtfalert::VERSION).not_to be nil
  end

  # it "creates an emtpy data file" do
  #   d = '/var/tmp' # TODO: create a tmpdir
  #   store = Wtfalert::Store.new(d)
  #   data = store.load
  #   expect(File).to exist(File.join(d,'alerts.yaml'))
  # end
end
