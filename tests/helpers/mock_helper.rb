# Use so you can run in mock mode from the command line
#
# FOG_MOCK=true fog

Fog.credentials[:libvirt_uri] = ENV.fetch("FOG_LIBVIRT_URI", "test:///default")

def real_libvirt?
  Fog.credentials[:libvirt_uri].start_with?("qemu")
end

enable_mocking = ENV.fetch("FOG_MOCK") { (!real_libvirt?).to_s }
Fog.mock! unless ["false", "no", "0"].include?(enable_mocking)
