require 'csv'
require 'nokogiri'

# roles as they appear in the source document:
roles = [
	:warrior_tank,
	:warrior_fury,
	:rogue,
	:hunter,
	:mage,
	:warlock,
	:priest_holy,
	:priest_shadow,
	:paladin_holy,
	:paladin_retri,
	:paladin_prot,
	:druid_resto,
	:druid_bear,
	:druid_cat,
	:druid_moonkin]

# output names:
role_names = {
	:warrior_tank => "Krieger Tank",
	:warrior_fury => "Krieger Fury",	
	:rogue => "Schurke",
	:hunter => "Jäger",
	:mage => "Magier",
	:warlock => "Hexenmeister",
	:priest_holy => "Priester Holy",
	:priest_shadow => "Priester Shadow",
	:paladin_holy => "Paladin Holy",
	:paladin_retri => "Paladin Retri",
	:paladin_prot => "Paladin Tank",
	:druid_resto => "Resto Druide",
	:druid_bear => "Bär",
	:druid_cat => "Katze",
	:druid_moonkin => "Boomkin"}

# output order:
output_role_order = [:mage,:warrior_tank,:warrior_fury,:rogue,:warlock,:hunter,:priest_holy,:priest_shadow,:paladin_holy,:paladin_retri,:druid_resto,:druid_cat,:druid_moonkin]

input_path = "in/aq40_prio.csv"
output_path = "out/aq40_prio.txt"
uri_column = 3
first_role_column = 4

role_prio_item = Struct.new(:role,:id,:prio)
role_prio_items = Array.new()

# collect prio items for each role:
values = CSV.read( input_path )
values.each do |row|
	item_uri = row[uri_column]

	match = /^https\:\/\/classic\.wowhead\.com\/item\=(?<item_id>\d+)\/.*$/.match( item_uri )
	
	if not match
		next
	end

	item_id = match[:item_id]

	roles.each_index {|index|
		prio = row[first_role_column+index]
		if prio
			role_prio_items << role_prio_item.new(roles[index],item_id.to_i,prio.to_i)
		end
	}
end

remaining_roles = roles
File.open(output_path,'w') {|file|
	output_role_order.each { |role|
		role_name = role_names[ role ]

		remaining_roles.delete(role)

		p1_items = role_prio_items.select { |item| item.role == role && item.prio == 1 }
		p2_items = role_prio_items.select { |item| item.role == role && item.prio == 2 }
		p3_items = role_prio_items.select { |item| item.role == role && item.prio == 3 }

		loop_count = [p1_items.size, p2_items.size, p3_items.size].max

		for i in 0..loop_count-1 do
			p1_item = p1_items[i]
			p2_item = p2_items[i]
			p3_item = p3_items[i]

			p1_id = p1_item ? p1_item.id : 0
			p2_id = p2_item ? p2_item.id : 0
			p3_id = p3_item ? p3_item.id : 0

			file.puts "#{role_name};#{p1_id};#{p2_id};#{p3_id}"
		end
	}
}

puts "Skipped roles #{remaining_roles.join(',')} in output"
