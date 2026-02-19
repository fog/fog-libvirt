require File.expand_path("../../../helper", __dir__)
require "fog/libvirt"

class DeleteIsoFakeVolume
  attr_reader :name, :deleted

  def initialize(name, &on_delete)
    @name = name
    @on_delete = on_delete
  end

  def delete
    @deleted = true
    @on_delete&.call(name)
    true
  end
end

class DeleteIsoFakePool
  def initialize(volumes = {})
    @volumes = volumes
  end

  def lookup_volume_by_name(volume_name)
    volume = @volumes[volume_name]
    raise ::Libvirt::RetrieveError, "volume not found" unless volume

    volume
  end
end

class DeleteIsoFakeClient
  def initialize(pool)
    @pool = pool
  end

  def lookup_storage_pool_by_name(_pool_name)
    @pool
  end
end

Shindo.tests("Fog::Compute[:libvirt] | destroy_iso") do
  tests("destroy_iso") do
    returns(true, "deletes an iso storage volume from a pool and verifies absence") do
      volumes = {}
      volume = DeleteIsoFakeVolume.new("os.iso") { |name| volumes.delete(name) }
      volumes["os.iso"] = volume
      pool = DeleteIsoFakePool.new(volumes)
      client = DeleteIsoFakeClient.new(pool)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      ok = service.destroy_iso("default", "os.iso")

      ok && volume.deleted
    end

    returns(true, "returns true when iso volume is already absent") do
      pool = DeleteIsoFakePool.new({})
      client = DeleteIsoFakeClient.new(pool)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      service.destroy_iso("default", "os.iso")
    end
  end
end
