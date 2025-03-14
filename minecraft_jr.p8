pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	add_recipes()
end

function _update()
	update_player()
end

function _draw()
	cls(3)
	camera(player.x-60,player.y-60)
	map(0,0,0,0,16,16)
	draw_player()
	draw_tracked_objs()
	draw_equipment()
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
}

function draw_player()
	spr(player.cur_spr,player.x,player.y,1,1,player.flip_spr)
	if(player.inventory_open) then end
	
	pos=get_tool_grid_pos()
	tilex=pos.x
	tiley=pos.y
	
 --rect(tilex*8,tiley*8,(tilex*8)+8,(tiley*8)+8,6)
 spr(5,tilex*8,tiley*8)

	draw_submenu(inventory)
	draw_submenu(craft_menu)
	draw_actionbar()
end

function update_player()
 if(not(actionbar.is_open)) then
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
	
		if(btnp(🅾️)) then
		 punch() 
		end
	
		
	 if(btnp(❎)) then toggle_actionbar() end
	end
	
	update_submenu(inventory)
	update_submenu(craft_menu)
	update_actionbar()
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
 ptilex=flr((player.x+4)/8)
	ptiley=flr((player.y+4)/8)
	
	tilex=ptilex
	tiley=ptiley
	
	if(player.dir=='left') then
	 tilex=tilex-1
	elseif(player.dir=='right') then
		tilex=tilex+1
	elseif(player.dir=='up') then
		tiley=tiley-1
	elseif(player.dir=='down') then
		tiley=tiley+1
	end
	
	return {x=tilex,y=tiley}
end

function punch()
	pos=get_tool_grid_pos()
	tilex=pos.x
	tiley=pos.y
	 
 tile=mget(tilex,tiley)
 
 if(tile!=0) then
 	tiledef=tiledefs[tile]
 	
 	if(not tiledef) then return end
 
 	punch_obj(tilex*8,tiley*8,tiledef)
 end
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
																print(item.amount,x+m.width-13,yy)
													 	else
													 	 print('--',x+8,yy)
													 	end															
														end
													end
												end,
	crsr_pos=1,
	item_action=function (m) end,
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
													 
													 if(yy>y+11) then
													 	if item then						 		
													  	print(item.name,x+8,yy)
													  	
													  	if(can_make(i)) then
														  	spr(9,x+m.width-10,yy-2)
														  end
													 	else
													 	 print('--',x+8,yy)
													 	end															
														end
													end
												end,
	item_action=function (m) 
														local item=m.items[m.crsr_pos]
														
														if item and can_make(m.crsr_pos) then
														 add_item_to_inv(item.name,1)
														 
														 for k,v in pairs(item.ingr) do
															 remove_item_from_inv(k,v)
															end
														end
													end
}

recipes={
	{
		name='pickaxe',
		ingr={
			wood=2,
			stone=2,
		}
	}
}

function add_recipes()
	local i=1
	for recipe in all(recipes) do
		craft_menu.items[i]=recipe
		i=i+1
	end
end

function can_make(idx)
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
		--spr(8,x,y+11+(7*(menu.crsr_pos-1)))
	end
end

function update_submenu(menu)
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
		tile=32
	},
	[33]={
		name='stone',
		drop='stone',
		durability=5,
		tile=33
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
 actionbar.x=player.x+actionbar.offset
 actionbar.y=player.y-55

	local submenu_is_open=
		inventory.is_open or
		craft_menu.is_open	
 
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

function draw_tracked_objs()
	for o in all(tracked_objs) do
		rectfill(o.x-2,o.y-1,o.x+9,o.y+2,1)
		
		hwidth=-2+(9*(o.health/o.durability))
		
		rectfill(o.x-1,o.y,o.x+hwidth,o.y+1,8)
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
		drop=drop
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
 
 if(obj) then
 	obj.health=obj.health-1
 else
 	obj=track_obj(x,y,tiledef.durability,tiledef.drop)
 	obj.health=obj.health-1
 end
 
	if(obj.health<=0) then
		add_item_to_inv(tiledef.drop,1)
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
-->8
equipment={
	x=4,
	y=120-21,
}

function draw_equipment()
	local x=player.x-60+equipment.x
	local y=player.y-60+equipment.y
	
	rectfill(x,y,x+24,y+24,1)
	rect(x+1,y+1,x+23,y+23,7)
end
__gfx__
00000000000000000111111000000000000000007770077700000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000111111001444410000000000000000071100117000b0000000800000007000000000000000000000000000000000000000000000000000000000000
007007000144441001f5f510000000000000000071000017000bb000000880000007700000000000008008000000000000000000000000000000000000000000
0007700001f5f51001fddd10000000000000000010000001000bbb00000888000007770000000b00000880000000000000000000000000000000000000000000
0007700001fddd1001188110000000000000000070000007000bbb00000888000007770000b0b000000880000000000000000000000000000000000000000000
0070070001188110001cc100000000000000000070000007000bb0000008800000077000000b0000008008000000000000000000000000000000000000000000
00000000001cc10000111100000000000000000077700777000b0000000800000007000000000000000000000000000000000000000000000000000000000000
00000000001111000000000000000000000000001110011100000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111155555555444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18788881144444411666566156666665499999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777771114411111666566156666665499999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18887881144444411555555156666665499999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18887881111144411656666156666665499999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17777771144441111656666156666665499999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
18788881144444411656666156666665499999940000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111155555555444444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00177100011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01bbb710116771100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13bbbbb1166677110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
133bbbb1155666610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
13333331115556510000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11144111011155100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00011000000111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000001111100001110000011111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011666110001610000016661000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100016111610001610000014111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ff100011141110001610000014100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ff100000141000011611000014100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000141000014441000014100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000141000011411000014100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000111000001110000011100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001010100000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000012141412002100200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000200012141412000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000002100200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
