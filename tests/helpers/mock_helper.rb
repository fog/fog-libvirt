# Use so you can run in mock mode from the command line
#
# FOG_MOCK=true fog

if ENV["FOG_MOCK"] == "true"
  Fog.mock!
end

Fog.credentials = {
  :libvirt_uri => 'test:///default'
}.merge(Fog.credentials)
