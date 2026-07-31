require File.expand_path("../../../helper", __dir__)
require "fog/libvirt"
require "tempfile"

class UploadIsoFakeVolume
  attr_reader :name, :path, :key, :deleted

  def initialize(name, path, key, &on_delete)
    @name = name
    @path = path
    @key = key
    @on_delete = on_delete
  end

  def upload(_stream, _offset, _length)
    true
  end

  def delete
    @deleted = true
    @on_delete&.call(name)
    true
  end
end

class UploadIsoFakePool
  attr_reader :xml, :volume, :deleted_volume_names

  def initialize(existing_volume_names = [])
    @existing_volume_names = existing_volume_names
    @deleted_volume_names = []
  end

  def create_vol_xml(xml)
    @xml = xml
    true
  end

  def list_volumes
    @existing_volume_names
  end

  def lookup_volume_by_name(name)
    on_delete = proc { |deleted_name| @deleted_volume_names << deleted_name } if @existing_volume_names.include?(name)
    UploadIsoFakeVolume.new(name, "/var/lib/libvirt/images/#{name}", "pool/#{name}", &on_delete)
  end
end

class UploadIsoFakeStream
  def sendall
    loop do
      count, _chunk = yield(nil, 4096)
      break if count.zero?
    end
  end

  def finish; end
end

class UploadIsoFakeClient
  def initialize(pool)
    @pool = pool
  end

  def lookup_storage_pool_by_name(_pool_name)
    @pool
  end

  def stream
    UploadIsoFakeStream.new
  end
end

Shindo.tests("Fog::Compute[:libvirt] | upload_iso") do
  tests("upload_iso") do
    returns(true, "creates and uploads an iso volume in the pool") do
      pool = UploadIsoFakePool.new
      client = UploadIsoFakeClient.new(pool)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      file = Tempfile.new(["os", ".iso"])
      file.write("test-iso")
      file.flush

      result = service.upload_iso("default", "os.iso", file.path)

      !pool.xml.nil? &&
        pool.xml.include?("<name>os.iso</name>") &&
        pool.xml.include?("<capacity") &&
        result[:pool_name] == "default" &&
        result[:name] == "os.iso" &&
        result[:path] == "/var/lib/libvirt/images/os.iso"
    ensure
      file.close
      file.unlink
    end

    returns(true, "replaces existing iso volume before upload when volume already exists") do
      pool = UploadIsoFakePool.new(["os.iso"])
      client = UploadIsoFakeClient.new(pool)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      file = Tempfile.new(["os", ".iso"])
      file.write("test-iso")
      file.flush

      result = service.upload_iso("default", "os.iso", file.path)

      pool.deleted_volume_names.include?("os.iso") &&
        !pool.xml.nil? &&
        pool.xml.include?("<name>os.iso</name>") &&
        result[:name] == "os.iso"
    ensure
      file.close
      file.unlink
    end
  end
end
