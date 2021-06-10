Shindo.tests("Fog::Compute[:libvirt] | list_pools request", 'libvirt') do

  compute = Fog::Compute[:libvirt]

  tests("Lists Pools") do
    response = compute.list_pools
    test("should be an array") { response.kind_of? Array }
    test("should have two pools") { response.length == 2 }
  end

  tests("Lists Inactive Pools") do
    inactive_pool = compute.mock_pool('inactive_pool1')
    inactive_pool[:active] = false
    compute.add_pool(inactive_pool)

    response = compute.list_pools({ :include_inactive => true })

    test("should be an array") { response.kind_of? Array }
    test("should have three pools") { response.length == 3 }
  end
end
