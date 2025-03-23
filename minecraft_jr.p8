pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
can_build=false

function _init()
	add_recipes()
	add_buildings()
	equipment.sprite=equipment_defs.pickaxe.sprite
	add_item_to_inv('hoe',999)
	add_item_to_inv('seeds',999)
	add_item_to_inv('wtrcan',999)
	add_item_to_inv('pickaxe',999)
	add_item_to_inv('axe',999)
	add_item_to_inv('wood',10)
end

function _update()
	can_build=true
	update_player()
	update_tracked_objs()
	update_clock()
	update_planting()
end

function _draw()
	cls(3)
	camera(player.x-60,player.y-60)
	map(0,0,0,0,16,16)
	draw_planting()
	draw_player()
	draw_tracked_objs()
	draw_clock()
	draw_equipment()
	
	if player.building!=0 then
		return
	end
	
	draw_submenu(inventory)
	draw_submenu(craft_menu)
	draw_submenu(build_menu)
	draw_actionbar()
end

-->8
player={
	cur_spr=1,
	x=1,
	y=1,
	inventory_open=false,
	dir='left',
	is_punching=false,
	punching_counter=0,
	punching_speed=10,
	anim_counter=0,
	anim_speed=20,
	flip_spr=false,
	moving=false,
	punch_timer=0,
	building=0,
	building_counter=0,
	building_speed=50,
	building_flash=false
}

function draw_player()
	spr(player.cur_spr,player.x,player.y,1,1,player.flip_spr)
	if(player.inventory_open) then end
	
	pos=get_tool_grid_pos()
	tilex=pos.x
	tiley=pos.y
	
	if player.building!=0 then
		if not player.building_flash then
			spr(player.building,tilex*8,tiley*8)
			print('building',player.x-11,player.y+56,10)
		end
		
		rect(player.x-59,player.y-59,player.x+66,player.y+66,10)
	end
	
	player.building_counter=player.building_counter+player.building_speed

	if player.building_counter>=1000 then
		player.building_flash=not player.building_flash
		player.building_counter=0
	end
		
	if is_valid_crsr_pos() then
 	spr(5,tilex*8,tiley*8)
 else
 	spr(12,tilex*8,tiley*8)
 end
end

function update_player()
	update_submenu(inventory)
	update_submenu(craft_menu)
	update_submenu(build_menu)
	update_actionbar()

 if(player.building!=0 or not(actionbar.is_open)) then
		local sx=player.x
		local sy=player.y
		
		if(btn(⬅️)) then 
			player.x=player.x-1
			player.dir='left' 
			player.flip_spr=true
			player.moving=true
		end
		if(btn(➡️)) then 
			player.x=player.x+1
			player.dir='right'
			player.flip_spr=false
			player.moving=true 
		end
		
		if(mcollide(player)) then
			player.x=sx
		end
		
		if(btn(⬆️)) then 
			player.y=player.y-1
			player.dir='up' 
			player.moving=true
		end
		if(btn(⬇️)) then 
			player.y=player.y+1
			player.dir='down' 
			player.moving=true
		end
		
		if(mcollide(player)) then
			player.y=sy
		end
		
		if(not(btn(⬆️) or btn(⬇️) or btn(⬅️) or btn(➡️))) then
			player.moving=false
			player.cur_spr=1
		end
		
		if(player.moving) then
			player.anim_counter=player.anim_counter+player.anim_speed
			
			if(player.anim_counter >= 100) then
				player.anim_counter=0
				
				if(player.cur_spr==1) then
					player.cur_spr=2
				else
					player.cur_spr=1
				end
			end
		end

		if player.building==0 then	
			if btnp(🅾️) and is_valid_crsr_pos() then
			 punch() 
			end
			
			if not btn(🅾️) then
				player.punch_timer=0
			end
		
		 if(btnp(❎)) then toggle_actionbar() end
		else
			if btnp(🅾️) and is_valid_crsr_pos() and can_build then
				if can_make_building(build_menu.crsr_pos) then			
					local pos=get_tool_grid_pos()
					local tilex=pos.x
					local tiley=pos.y
					
					local t=mget(tilex,tiley)
					
					if t==0 then
						mset(tilex,tiley,player.building)
																 
					 for k,v in pairs(tiledefs[player.building].ingr) do
						 remove_item_from_inv(k,v)
						end
					end
				else
					player.building=0
				end
			end
			
			if btnp(❎) then
				player.building=0
			end
		end
	end
end

function toggle_actionbar()
	if(not inventory.is_open) then
		if(actionbar.is_open) then
			actionbar.is_closing=true
		else
			actionbar.crsr_pos=1
			actionbar.is_opening=true
		end
	end
end

function get_tool_grid_pos()
	local px=player.x
	local py=player.y
	local ox=0
	local oy=0
	
	if(player.dir=='left') then
		ox=-1
		py+=4
	elseif(player.dir=='right') then
		px+=7
		py+=4
		ox=1
	elseif(player.dir=='up') then
		oy=-1
		px+=4
	elseif(player.dir=='down') then
		px+=4
		py+=7
		oy=1
	end
	
	ptilex=flr((px)/8)+ox
	ptiley=flr((py)/8)+oy
	
	return {x=ptilex,y=ptiley}
end

function punch()
	local pos=get_tool_grid_pos()
	local tilex=pos.x
	local tiley=pos.y
	 
 local tile=mget(tilex,tiley)
 local is_structure=fget(tile,1)

	local equipdef=get_equipment_by_sprite(equipment.sprite)
	if equipdef.action then
		equipdef.action(tilex,tiley)
	end
 
 if(tile!=0) then
 	harvest_plant(tilex,tiley)
 	
 	local tiledef=tiledefs[tile]

		if not tiledef then return end

 	if is_structure then
	 	if player.punch_timer>0 then
	 		local power=1
	 	
	 		punch_obj(tilex*8,tiley*8,tiledef)
	 	else
	 		if tiledef.action then
	 			tiledef.action(tilex,tiley)
	 		end
	 		
	 		player.punch_timer=player.punch_timer+1
			end
 	elseif tiledef.durability then
	 	if(not tiledef) then return end
	 
	 	punch_obj(tilex*8,tiley*8,tiledef)
 	end
 end
end

function set_building(sprite)
	player.building=sprite
end

function is_valid_crsr_pos()
	local pos=get_tool_grid_pos()
	local x=pos.x
	local y=pos.y
	
	local ptx=flr(player.x/8)
	local pty=flr(player.y/8)
	
	if ptx==x and pty==y then
		return false
	end
	
	local tile=mget(x,y)
	local tiledef=tiledefs[tile]
	
	if tile!=0 and (not tiledef or not tiledef.interactable) then
		return false
	end
	
	return true
end

-->8
inventory={
	name='items',
	is_open=false,
	is_opening=false,
	is_closing=false,
	x=10,
	y=10,
	height=0,
	max_height=84,
	width=50,
	open_speed=30,
	max_items=10,
	items={},
	draw_items=function (m)
													local x,y = unpack(get_offset_pos(m.x,m.y))
													local scrolly=y-(m.crsr_pos-1)*7
													
													local items=m.items
													
													for i=1,m.max_items do
													 local yy=scrolly+12+(7*(i-1))
													 local item=items[i]
													 
													 if(yy>y+11) then
													 	if item then
													  	print(item.name,x+8,yy)
																print(pad_num(item.amount),x+m.width-13,yy)
													 	else
													 	 print('--',x+8,yy)
													 	end															
														end
													end
												end,
	crsr_pos=1,
	item_action=function (m)
														local item=get_inv_item_at_crsr()
														
														if item and equipment_defs[item.name] then
															equipment.sprite=equipment_defs[item.name].sprite
														end
													end,
}

craft_menu={
	name='craft',
	is_open=false,
	is_opening=false,
	is_closing=false,
	x=10,
	y=10,
	height=0,
	max_height=90,
	width=50,
	open_speed=30,
	max_items=30,
	items={},
	crsr_pos=1,
	draw_items=function (m)
													local x,y = unpack(get_offset_pos(m.x,m.y))
													local scrolly=y-(m.crsr_pos-1)*7
													
												
													for i=1,m.max_items do
													 local yy=scrolly+12+(7*(i-1))
													 local item=m.items[i]
													 
													 if(yy>y+11 and yy<y+m.max_height-4) then
													 	if item then						 		
													  	print(item.name,x+8,yy)
													  	
													  	if(can_make_recipe(i)) then
														  	spr(9,x+m.width-10,yy-2)
														  end
													 	else
													 	 print('--',x+8,yy)
													 	end															
														end
													end
													
													local hovered_recipe=get_recipe_at_crsr()
													
													if hovered_recipe then
														local sx,sy=54,40
														local sw,sh=60,60
													 rectfill(x+sx,y+sy,x+sx+sw,y+sy+sh,1)
													 rect(x+sx+1,y+sy+1,x+sx+sw-1,y+sy+sh-1,7)
													 
													 local sprite=equipment_defs[hovered_recipe.name].sprite
													 local sprx=x+sx+((sw-2)/2)-3
													 local spry=y+sy+4
													 
													 spr(sprite,sprx,spry)
													 
													 line(x+sx+1,y+sy+14,x+sx+sw-1,y+sy+14,7)
													 
													 local i=0
													 for k,v in pairs(hovered_recipe.ingr) do
													 	local yy=y+sy+16+(7*i)
													 	
													 	print(k,x+sx+3,yy,7)
													 	
													 	local item=find_inv_item(k)
													 	
													 	local clor=7
													 	
													 	if item then
													 		if item.amount<v then
													 			clor=8
													 		end
													 	 print(pad_num(item.amount),x+sx+sw-29,yy,clor)
													 	else
													 		clor=8
													 		print(pad_num(0),x+sx+sw-29,yy,clor)
													 	end
													 	
													 	
													 	print('/',x+sx+sw-17,yy,clor)
													 	print(pad_num(v),x+sx+sw-13,yy,clor)
													 	i=i+1
													 end
													end
												end,
	item_action=function (m) 
														local item=m.items[m.crsr_pos]
														
														if item and can_make_recipe(m.crsr_pos) then
														 add_item_to_inv(item.name,1)
														 
														 for k,v in pairs(item.ingr) do
															 remove_item_from_inv(k,v)
															end
														end
													end
}

build_menu={
	name='build',
	is_open=false,
	is_opening=false,
	is_closing=false,
	x=10,
	y=10,
	height=0,
	max_height=90,
	width=50,
	open_speed=30,
	max_items=30,
	items={},
	crsr_pos=1,
	draw_items=function (m)
													local x,y = unpack(get_offset_pos(m.x,m.y))
													local scrolly=y-(m.crsr_pos-1)*7
													
													print(#m.items,x,y-10)
													
													for i=1,m.max_items do
													 local yy=scrolly+12+(7*(i-1))
													 local item=m.items[i]
													 
													 if(yy>y+11 and yy<y+m.max_height-4) then
													 	if item then						 		
													  	print(item.name,x+8,yy)
													  	
													  	if(can_make_building(i)) then
														  	spr(9,x+m.width-10,yy-2)
														  end
													 	else
													 	 print('--',x+8,yy)
													 	end															
														end
													end
													
													local hovered_building=get_building_at_crsr()
													
													if hovered_building then
														local sx,sy=54,40
														local sw,sh=60,60
													 rectfill(x+sx,y+sy,x+sx+sw,y+sy+sh,1)
													 rect(x+sx+1,y+sy+1,x+sx+sw-1,y+sy+sh-1,7)
													 
													 local sprite=tiledefs[hovered_building.tile].tile
													 local sprx=x+sx+((sw-2)/2)-3
													 local spry=y+sy+4
													 
													 spr(sprite,sprx,spry)
													 
													 line(x+sx+1,y+sy+14,x+sx+sw-1,y+sy+14,7)
													 
													 local i=0
													 for k,v in pairs(hovered_building.ingr) do
													 	local yy=y+sy+16+(7*i)
													 	
													 	print(k,x+sx+3,yy,7)
													 	
													 	local item=find_inv_item(k)
													 	
													 	local clor=7
													 	
													 	if item then
													 		if item.amount<v then
													 			clor=8
													 		end
													 	 print(pad_num(item.amount),x+sx+sw-29,yy,clor)
													 	else
													 		clor=8
													 		print(pad_num(0),x+sx+sw-29,yy,clor)
													 	end
													 	
													 	
													 	print('/',x+sx+sw-17,yy,clor)
													 	print(pad_num(v),x+sx+sw-13,yy,clor)
													 	i=i+1
													 end
													end
												end,
	item_action=function (m) 
														local item=m.items[m.crsr_pos]
														
														if item and can_make_building(m.crsr_pos) then
														 set_building(item.tile)
															-- when switching back to build, prevent building until the next frame
															-- this is a hack to prevent button press from propagating down and immediately placing the building
															can_build=false
														end
													end
}

function add_recipes()
	local i=1
	for recipe in all(recipes) do
		craft_menu.items[i]=recipe
		i=i+1
	end
end

function add_buildings()
	local i=1
	for k,v in pairs(tiledefs) do
		if v.buildable then
			build_menu.items[i]=v
			i=i+1
		end
	end
end

function can_make_recipe(idx)
	local ingr=recipes[idx].ingr
	local can=true
	
	for k,v in pairs(ingr) do
		local inv_item=find_inv_item(k)
		
		if(inv_item) then
			if(inv_item.amount<v) then
				can=false
			end
		else
			can=false
		end
	end
	
	return can
end

function can_make_building(idx)
	local ingr=build_menu.items[idx].ingr
	local can=true
	
	for k,v in pairs(ingr) do
		local inv_item=find_inv_item(k)
		
		if(inv_item) then
			if(inv_item.amount<v) then
				can=false
			end
		else
			can=false
		end
	end
	
	return can
end

function find_inv_item(name)
	for item in all(inventory.items) do
		if item.name == name then
			return item
		end
	end
end

function get_offset_pos(x,y)
	return {player.x-60+x,player.y-60+y}
end

function draw_submenu(menu)
 local x,y=unpack(get_offset_pos(menu.x,menu.y))
 
	if(menu.is_opening or menu.is_closing) then
	 rectfill(x,y,x+menu.width,y+menu.height,1)
	elseif(menu.is_open) then
	 rectfill(x,y,x+menu.width,y+menu.height,1)
		rect(x+1,y+1,x+menu.width-1,y+menu.height-1,7)
		print(menu.name,x+3,y+3)
	 line(x+1,y+9,x+menu.width-1,y+9,7)
	
		menu.draw_items(menu)
		
		spr(8,x,y+11)
	end
end

function update_submenu(menu)
	if player.building!=0 then
		return
	end
	
	if(not(menu.is_open) and menu.is_opening) then
 	if(menu.height<menu.max_height) then
 	 local amt=inventory.open_speed
 	 
 	 if(menu.height+menu.open_speed>menu.max_height) then
 	 	amt=menu.max_height-inventory.height
 	 end
 	 
 	 menu.height=menu.height+amt
 	else
 		menu.is_open=true
 		menu.is_opening=false
 	end
 elseif(menu.is_open and menu.is_closing) then
 	if(menu.height>0) then
 		local amt=menu.open_speed
 		
 		if(menu.height-amt<0) then
 			amt=menu.height
 		end
 		
 		menu.height=menu.height-amt
 	else
 		menu.is_open=false
 		menu.is_closing=false
 	end
 end
 
 if(menu.is_open) then
 	if(btnp(⬇️)) then
	  if(menu.crsr_pos<menu.max_items) then
	 	 menu.crsr_pos=menu.crsr_pos+1
	 	end
 	end
 
	 if(btnp(⬆️)) then
	  if(menu.crsr_pos>1) then
	 	 menu.crsr_pos=menu.crsr_pos-1
	 	end
	 end
	 
	 if(btnp(🅾️)) then
	 	menu.item_action(menu)
	 end
 
 	if(btnp(❎)) then
 		menu.is_closing=true
 	end
 end
end

function add_item_to_inv(name,amount)
	for item in all(inventory.items)  do		
		if item and item.name==name then
			item.amount=item.amount+amount
			return true
		end
	end
	
	if #inventory.items<inventory.max_items then
		add(inventory.items,{name=name,amount=amount})
		return true
	end

	return false
end

function remove_item_from_inv(name,amount)
	local item=find_inv_item(name)
	
	item.amount=item.amount-amount
	
	if item.amount<=0 then
		del(inventory.items,item)
	end
end

function get_inv_item_at_crsr()
	return inventory.items[inventory.crsr_pos]
end

function get_recipe_at_crsr()
		return recipes[craft_menu.crsr_pos]
end

function get_building_at_crsr()
	return build_menu.items[build_menu.crsr_pos]
end

function flatten_items(items)
	local i=0
	
	local is={}
	
	for k,v in qsort(pairs(items)) do
		is[i]={k,v}
		i=i+1
	end
	
	return is
end
-->8
tiledefs={
	[32]={
		name='tree',
		drop='wood',
		durability=5,
		tile=32,
		weakness='chop',
		interactable=true
	},
	[33]={
		name='stone',
		drop='stone',
		durability=5,
		tile=33,
		weakness='mine',
		interactable=true,
	},
	[21]={
		name='door',
		drop='wood',
		durability=10,
		tile=21,
		action=function (x,y)
										mset(x,y,22)
									end,
		buildable=true,
		ingr={
			wood=10
		},
		interactable=true,
	},
	[22]={
		name='door_opened',
		drop='wood',
		durability=10,
		tile=22,
		action=function (x,y)
										mset(x,y,21)
									end,
		ingr={
			wood=10
		},
		interactable=true,
	},
	[18]={
		name='stn wall',
		durability=10,
		tile=18,
		buildable=true,
		ingr={
			stone=10
		},
		interactable=true,
	},
	[20]={
		name='wd floor',
		durability=2,
		tile=20,
		buildable=true,
		ingr={
			wood=3
		},
		interactable=true
	},
	[34]={
		name='dirt',
		tile=34,
		interactable=true
	},
	[35]={
		name='dirt_watered',
		tile=35,
		interactable=true
	}
}
-->8
actionbar={
	x=160,
	y=160,
	offset=75,
	is_opening=false,
	is_open=false,
	is_closing=false,
	crsr_pos=1
}

function draw_actionbar()
 draw_action('items',0,0,30,10,1)
 draw_action('craft',0,12,30,10,2)
 draw_action('build',0,24,30,10,3)
end

function draw_action(text,x,y,w,h,idx)
 offset=0
 hicolor=6
 if(actionbar.crsr_pos==idx) then
  offset=4
  hicolor=7
 end
 
 xx=actionbar.x+x-offset
 yy=actionbar.y+y
 
 
 rectfill(xx,yy,xx+w,yy+h,1)
 rect(xx+1,yy+1,xx+w-1,yy+h-1,hicolor)
 print(text,xx+3,yy+3,hicolor)
end

function update_actionbar()
	if player.building!=0 then
		return
	end

 actionbar.x=player.x+actionbar.offset
 actionbar.y=player.y-55

	local submenu_is_open=
		inventory.is_open or
		craft_menu.is_open	or
		build_menu.is_open
 
 if actionbar.is_opening and actionbar.offset>45 then
		actionbar.offset=actionbar.offset-8
	elseif actionbar.is_opening and actionbar.offset<=45 then
		actionbar.is_opening=false
		actionbar.is_open=true
	end
	
	if actionbar.is_closing and actionbar.offset<75 then
		actionbar.offset=actionbar.offset+8
	elseif actionbar.is_closing and actionbar.offset>=75 then
		actionbar.is_closing=false
		actionbar.is_open=false
	end

	if (actionbar.is_open and not submenu_is_open) then
	 if(btnp(⬇️)) then
	  if(actionbar.crsr_pos<3) then
	 	 actionbar.crsr_pos=actionbar.crsr_pos+1
	 	end
 	end
 
	 if(btnp(⬆️)) then
	  if(actionbar.crsr_pos>1) then
	 	 actionbar.crsr_pos=actionbar.crsr_pos-1
	 	end
	 end
	 
	 if(btnp(🅾️)) then
	 	if actionbar.crsr_pos==1 then
				inventory.crsr_pos=1
				inventory.is_opening=true
			elseif actionbar.crsr_pos==2 then
				craft_menu.crsr_pos=1
				craft_menu.is_opening=true
			elseif actionbar.crsr_pos==3 then
				build_menu.crsr_pos=1
				build_menu.is_opening=true
			end
	 end
	 
	 if(btnp(❎)) then
	 	actionbar.is_closing=true
	 end
	end
end

-->8
tracked_objs={

}

local timeout=100

function draw_tracked_objs()
	for o in all(tracked_objs) do
		rectfill(o.x-2,o.y-1,o.x+9,o.y+2,1)
		
		hwidth=(9*(o.health/o.durability))
		
		rectfill(o.x-1,o.y,o.x+hwidth,o.y+1,8)
	end
end

function update_tracked_objs()
	for o in all(tracked_objs) do
		o.timer=o.timer+1
		
		if o.timer>timeout then
			untrack_obj(o.x,o.y)
		end
	end
end

function find_obj(x,y)
	obj=nil
	
	for o in all(tracked_objs) do
		if(o.x==x and o.y==y) then
			obj=o
		end
	end
	
	return obj
end

function track_obj(x,y,durability,drop)
	newobj={
		x=x,
		y=y,
		durability=durability,
		health=durability,
		drop=drop,
		timer=0,
	}
	
	add(tracked_objs,newobj)
	
	return newobj 
end

function untrack_obj(x,y)
	obj=find_obj(x,y)
	
	if(not obj) then return end
	
	del(tracked_objs,obj)
end

function punch_obj(x,y,tiledef)
 obj=find_obj(x,y)
 
 if not obj then
 	obj=track_obj(x,y,tiledef.durability,tiledef.drop)
 end
 
	local power=1
	
	local equip=get_equipment_by_sprite(equipment.sprite)
	
	if equip and tiledef.weakness then
		if tiledef.weakness==equip.affinity then
			power=equipment_defs.pickaxe.power
		else
			power=equipment_defs.pickaxe.power/4
		end
	end
 
 obj.timer=0
 obj.health=obj.health-power
 
	if(obj.health<=0) then
		if tiledef.ingr then
			for k,v in pairs(tiledef.ingr) do
				add_item_to_inv(k,v)
			end
		elseif tiledef.drop then
			add_item_to_inv(tiledef.drop,1)
		end
		mset(tilex,tiley,0)
		untrack_obj(x,y)
	end
end
-->8
function mcollide(obj)	
	local x1=obj.x/8
 local y1=obj.y/8
 local x2=(obj.x+7)/8
 local y2=(obj.y+7)/8
 
 local a=fget(mget(x1,y1),0)
 local b=fget(mget(x1,y2),0)
 local c=fget(mget(x2,y1),0)
 local d=fget(mget(x2,y2),0)
  
 return a or b or c or d
end

function mcollide_pos(obj)
	local x1=obj.x/8
 local y1=obj.y/8
 local x2=(obj.x+7)/8
 local y2=(obj.y+7)/8
 
 local a=fget(mget(x1,y1),0)
 local b=fget(mget(x1,y2),0)
 local c=fget(mget(x2,y1),0)
 local d=fget(mget(x2,y2),0)
  
 if a then
 	return {x1,x2}
 elseif b then
 	return {x1,y2}
 elseif c then
 	return {x2,y1}
 elseif d then
 	return {x2,y2}
 end
end
-->8
equipment={
	x=4,
	y=120-21,
	sprite=0
}

function draw_equipment()
	local x=player.x-60+equipment.x
	local y=player.y-60+equipment.y
	
	rectfill(x,y,x+24,y+24,1)
	rect(x+1,y+1,x+23,y+23,7)
	
	if equipment.sprite==0 then
		print('empty',x+3,y+10)
	else
		local sx,sy=(equipment.sprite % 16) * 8, (equipment.sprite \ 16) * 8
		sspr(sx,sy,8,8,x+4,y+4,16,16)
	end
end

function get_equipment_by_sprite(sprite)
	for k,v in pairs(equipment_defs) do
		if v.sprite==sprite then
			return v
		end
	end
end
-->8
recipes={
	{
		name='pickaxe',
		ingr={
			wood=2,
			stone=2,
		}
	},
	{
		name='sword',
		ingr={
			wood=2,
			stone=2,
		}
	},
	{
		name='wtrcan',
		ingr={
			stone=2
		}
	},
	{
		name='hoe',
		ingr={
			wood=2,
			stone=2,
		}
	}
}
-->8
equipment_defs={
	pickaxe={
		sprite=49,
		power=2,
		affinity='mine'
	},
	sword={
		sprite=50,
		power=2
	},
	hoe={
		sprite=51,
		power=2,
		action=function (tilex,tiley)
										local t=mget(tilex,tiley)
										
										if t==0 then
											mset(tilex,tiley,34)
										elseif t==34 or t==35 then
											mset(tilex,tiley,0)
										end
									end
	},
	axe={
		sprite=52,
		power=2,
		affinity='chop'
	},
	shovel={
		sprite=53,
		power=2
	},
	wtrcan={
		sprite=54,
		power=2,
		action=function (tilex,tiley)
										local tile=mget(tilex,tiley)
										
										--water the dirt patch
										if tile==34 then
											mset(tilex,tiley,35)
										end
									end
	},
	seeds={
		sprite=55,
		power=2,
		action=function (tilex,tiley)
										local tile=mget(tilex,tiley)
										
										if tile==34 or tile==35 then
											create_plant('carrot',tilex,tiley)
										end
									end
	}
}
-->8
function pad_num(num)
	if num < 10 then
		return '  ' .. tostr(num)
	elseif num < 100 then
		return ' ' .. tostr(num)
	end
	
	return num
end
-->8
clock={
	cur_time=0,
	nighttime_length=9000,
	daytime_length=9000,
	speed=1,
	is_day=true
}

function draw_clock()
	local clockx=player.x+40
	local clocky=player.y+45
	local clockw=8*3-1
	local clockh=8*2-1
	local clockx2=clockx+clockw
	local clocky2=clocky+clockh
	
	local length=clock.daytime_length
	local progress=clock.cur_time/length
	local planetx=clockx+3+((clockw-6)*progress)
	local planetc=10
	local skyc=12
	
	if not clock.is_day then
		length=clock.nighttime_length
		planetc=7
		skyc=1
	end

	rectfill(clockx,clocky,clockx2,clocky2,skyc)

	circfill(planetx,clocky+13,1,planetc)
	
	spr(64,clockx,clocky,3,3)

	rect(clockx+3,clocky+10,clockx2-3,clocky2+1,1)
end

function update_clock()
	clock.cur_time=clock.cur_time+clock.speed
	
	if clock.is_day and clock.cur_time > clock.daytime_length then
		clock.is_day=false
		pal({[0]=0,129,2,131,132,133,134,135,136,137,138,139,140,141,142,143},1)
		clock.cur_time=0
	elseif not clock.is_day and clock.cur_time > clock.nighttime_length then
		clock.is_day=true
		pal({[0]=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15},1)
		clock.cur_time=0
	end
end
-->8
planting={
	plants={},
	speed=10,
	timeout=1000,
}

growthdefs={
	seed=36,
	sprout=37,
	plant=38
}

function update_planting()
	for plant in all(planting.plants) do
		plant.counter+=planting.speed

		if plant.counter>=planting.timeout then
			if plant.sprite==growthdefs.seed then
				plant.sprite=growthdefs.sprout
			elseif plant.sprite==growthdefs.sprout then
				plant.sprite=growthdefs.plant
			end
			plant.counter=0
		end
	end
end

function draw_planting()
	for plant in all(planting.plants) do
		local x=plant.tilex*8
		local y=plant.tiley*8
		spr(plant.sprite,x,y)
	end
end

function find_plant(tilex,tiley)
	for plant in all(planting.plants) do
		if plant.tilex==tilex and plant.tiley==tiley then
			return plant
		end
	end
end

function can_create_plant(tilex,tiley)
	local p=find_plant(tilex,tiley)
	
	return not p
end

function create_plant(name,tilex,tiley)
	if can_create_plant(tilex,tiley) then
		add(planting.plants,{
			name=name,
			tilex=tilex,
			tiley=tiley,
			counter=0,
			sprite=growthdefs.seed
		})
	end
end

function harvest_plant(tilex,tiley)
	local p=find_plant(tilex,tiley)
	local can_harvest=p and p.sprite==growthdefs.plant
	
	if can_harvest then
		add_item_to_inv(p.name,2)
		
		del(planting.plants,p)
	end
end
__gfx__
00000000000000000111111000000000000000007770077700000000000000000000000000000000000000000000000088800888000000000000000000000000
000000000111111001444410000000000000000071100117000b0000000800000007000000000000000000000000000081100118000000000000000000000000
007007000144441001f5f510000000000000000071000017000bb000000880000007700000000000008008000040440081000018000000000000000000000000
0007700001f5f51001fddd10000000000000000010000001000bbb00000888000007770000000b00000880000040040010000001000000000000000000000000
0007700001fddd1001188110000000000000000070000007000bbb00000888000007770000b0b000000880000040400080000008000000000000000000000000
0070070001188110001cc100000000000000000070000007000bb0000008800000077000000b0000008008000040440080000008000000000000000000000000
00000000001cc10000111100000000000000000077700777000b0000000800000007000000000000000000000000000088800888000000000000000000000000
00000000001111000000000000000000000000001110011100000000000000000000000000000000000000000000000011100111000000000000000000000000
11111111111111111111111166666666494949491111111111100001154545331111111100111111111111003355455115545533333333333355455100000000
18788881144444411777177166566666949494941444444114100001155453335555555501555555555555103335545115455333333333333335545100000000
17777771114411111777177166666666494949491444444114100001154553335454545415554545545455515335455115545335533553353335455100000000
18887881144444411111111166666656949494941444414114100001155455334545454515545454454545515554545115454555455545553354545100000000
18887881111144411616666166666666494949491444414114100001154545335554555415454555555454514545455115545454545454543355455100000000
17777771144441111111111166566666949494941444444114100001155453335335533515545335533545515454555115554545454545453335545100000000
18788881144444411666616166666566494949491444444114100001154553333333333315455333333554515555551001555555555555553335455100000000
11111111111111111111111166666666949494941111111111100001155455333333333315545533335545511111110000111111111111113354545100000000
00011000000000000000000000000000000000000000000001001110000000000000000000000000000000000000000000000000000000000000000000000000
0017710001111100004444000044440000000000000000001b11bbb1000000000000000000000000000000000000000000000000000000000000000000000000
01bbb7101167711004ffff400499994000000000000000001bbb1b10000000000000000000000000000000000000000000000000000000000000000000000000
13bbbbb11666771104ffff4004999940004040000bb0bbb001b1bb10000000000000000000000000000000000000000000000000000000000000000000000000
133bbbb11556666104ffff40049999400004040000b00b0001b11b10000000000000000000000000000000000000000000000000000000000000000000000000
133333311155565104ffff4004999940000000000000000000100100000000000000000000000000000000000000000000000000000000000000000000000000
11144111011155100044440000444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111100001110000111110000011100011111000000000001110000000000000000000000000000000000000000000000000000000000000000000
00000000011666110001610000166610001116100014441001110000014711000000000000000000000000000000000000000000000000000000000000000000
00111100016111610001610000141110001666100011411001610111147444100000000000000000000000000000000000000000000000000000000000000000
001ff100011141110001610000141000001666100011411011111161174994410000000000000000000000000000000000000000000000000000000000000000
001ff100000141000011611000141000001416100016661016666661149999410000000000000000000000000000000000000000000000000000000000000000
00111100000141000014441000141000001411100016661016651161144994410000000000000000000000000000000000000000000000000000000000000000
00000000000141000011411000141000001410000011611016651111014444100000000000000000000000000000000000000000000000000000000000000000
00000000000111000001110000111000001110000001110011111000001111000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42222222222222222222222400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42999999999999999999992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42999999994944999999992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42994999994994999994992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42944499994949999944492400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42994999994944999994992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42999999999999999999992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42444444444444444444442400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42999999999999999999992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42900000000000000000092400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42999999999999999999992400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
42222222222222222222222400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000003030302020302000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
191818181818181818181818181818181818181818181a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
172000210020000020000021002000000000000000001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000001212121212000000000000002100000000001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000001214141412210020000000200000210000001e002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170020001214141412000000000000000000000000201e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000001215121212000000000020002100200000001e000000002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000000000000000000020000000000000200000001e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000210020000000000000000000200000000000211e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000000000222200212000000000000000000000001e000021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170021000000232300000000200000002100000000001e000000000021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000000000200021000000000000000020000020001e000021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
172000000000000000002000000020000000000000001e200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000000020000000000000000000000000000021001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000000000000000000000200000000000200000001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
170000000000000020000000000000200000000000001e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1d1b000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000002100200000002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000021000000002000002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000200000002100000021000020000000000000200000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000200000000000000000000000000000002100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
