class LocationContainersSubreport < AbstractSubreport
  def initialize(parent_report, location_id)
    super(parent_report)
    @location_id = location_id
  end

  def query
    query_string = "select
	indicator as top_container_indicator,
	barcode as top_container_barcode,
	ils_item_id,
	ils_holding_id,
  name as repository,
  tbl.id as id from
	(select top_container_id as id from top_container_housed_at_rlshp
  where location_id = #{@location_id}) as tbl
    natural join top_container
    join repository on repo_id = repository.id"
    db.fetch(query_string)
  end

  def fix_row(row)
    row[:container_profile] = query_profiles(row[:id])
    row[:records] = ContainerResourcesAccessionsSubreport
                          .new(self, row[:id]).get
    row.delete(:id)
  end

  def query_profiles(container_id)
    query_string = "select name from
	container_profile join top_container_profile_rlshp
    on container_profile.id = container_profile_id
where top_container_id = #{container_id}"
    profiles = db.fetch(query_string)
    profile_string = ''
    profiles.each do |profile_row|
      profile = profile_row.to_hash
      next unless profile[:name]
      profile_string += ', ' if profile_string != ''
      profile_string += profile[:name]
    end
    profile_string.empty? ? nil : profile_string
  end
end