pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- s.c.r.a.p.
-- space cleaning rules
-- and procedures

-------------------------------
-- globals & constants
-------------------------------

-- game states
st_intro,st_brief,st_play,st_success,st_fail,st_scores,st_namein=0,1,2,3,4,5,6

state,lvl,max_lvl,score,total_score,frame=st_intro,1,10,0,0,0

-- ui feedback
warn_scroll,warn_text=-1,""

-- camera
cam_x,cam_y,cam_ox,cam_oy=0,0,0,0

-- physics
friction,max_spd=0.995,2

-- controls
reverse_rot=true -- true=left steers left (ship rotates cw), false=direct
difficulty,menu_sel=1,0 -- difficulty 0-3, menu_sel 0=rotation 1=difficulty
diff_names={"intern","employee","manager","ceo"}

-------------------------------
-- ship
-------------------------------
ship={}

function init_ship(x,y,ang,fuel)
 ship={
  x=x,y=y,
  dx=0,dy=0,
  ang=ang or 0,
  fuel=fuel or 50,
  thrust_f=0, -- forward visual
  thrust_b=0, -- brake visual
  thrust_l=0, -- left visual
  thrust_r=0, -- right visual
  item=1, -- selected item (1=laser,2=cable)
  ammo=10,
  cable_out=false,
  cable_tgt=nil,
  alive=true,
  hp=3,
  dmg_timer=0,
  snd_main=false,
  snd_lat=false
 }
end

function update_ship()
 if not ship.alive then return end
 if ship.dmg_timer>0 then ship.dmg_timer-=1 end

 local lv=levels[lvl]
 -- difficulty: 0=intern,1=employee,2=manager,3=ceo
 local fm=split"0.7,1.5,2.5,4"[difficulty+1]
 local pwr,rpwr,bpwr=0.06,0.02,0.03

 -- reset thrust visuals
 ship.thrust_f,ship.thrust_b,ship.thrust_l,ship.thrust_r=0,0,0,0

 -- forward thrust (up)
 if btn(2) and lv.has_fwd and ship.fuel>0 then
  ship.dx+=cos(ship.ang)*pwr
  ship.dy+=sin(ship.ang)*pwr
  ship.fuel-=0.15*fm
  ship.thrust_f=1
 end

 -- brake thrust (down)
 if btn(3) and lv.has_fwd and ship.fuel>0 then
  ship.dx-=cos(ship.ang)*bpwr
  ship.dy-=sin(ship.ang)*bpwr
  ship.fuel-=0.1*fm
  ship.thrust_b=1
 end

 -- rotate
 local rdir=reverse_rot and 1 or -1
 if btn(0) and lv.has_rot and ship.fuel>0 then
  ship.ang+=rpwr*rdir
  ship.fuel-=0.05*fm
  if reverse_rot then ship.thrust_r=1 else ship.thrust_l=1 end
 end
 if btn(1) and lv.has_rot and ship.fuel>0 then
  ship.ang-=rpwr*rdir
  ship.fuel-=0.05*fm
  if reverse_rot then ship.thrust_l=1 else ship.thrust_r=1 end
 end

 -- main thruster sound (channel 3)
 local main_thrust=ship.thrust_f==1 or ship.thrust_b==1
 if main_thrust then
  if not ship.snd_main then
   sfx(8,3)
   ship.snd_main=true
  end
 else
  if ship.snd_main then
   sfx(-1,3)
   ship.snd_main=false
  end
 end
 -- lateral thruster sound (channel 2)
 local lat_thrust=ship.thrust_l==1 or ship.thrust_r==1
 if lat_thrust then
  if not ship.snd_lat then
   sfx(9,2)
   ship.snd_lat=true
  end
 else
  if ship.snd_lat then
   sfx(-1,2)
   ship.snd_lat=false
  end
 end

 -- item cycle (o button)
 if btnp(4) and lv.has_items then
  if lv.has_cable then
   ship.item=ship.item==1 and 2 or 1
   sfx(3)
  end
 end

 -- use item (x button)
 if btnp(5) and lv.has_items then
  if ship.item==1 and ship.ammo>0 then
   fire_laser()
  elseif ship.item==2 and lv.has_cable then
   toggle_cable()
  end
 end

 -- warn on disabled controls
 if (btnp(0) or btnp(1)) and not lv.has_rot
 or (btnp(4) or btnp(5)) and not lv.has_items then
  sfx(6)
  if warn_scroll<-(#warn_text*4) then
   local msg="cONTROL LOCKED FOR THIS TEST. pLEASE ONLY USE "
   if lv.has_fwd then msg=msg.."UP/DOWN: THRUST/BRAKE " end
   if lv.has_rot then msg=msg.."LEFT/RIGHT: ROTATE " end
   if lv.has_items then msg=msg.."z: CYCLE x: USE " end
   warn_text=msg
   warn_scroll=128
  end
 end
 if warn_scroll>=-(#warn_text*4) then
  warn_scroll-=1
 end

 -- apply friction
 ship.dx*=friction
 ship.dy*=friction

 -- clamp speed
 local spd=sqrt(ship.dx*ship.dx+ship.dy*ship.dy)
 if spd>max_spd then
  ship.dx=ship.dx/spd*max_spd
  ship.dy=ship.dy/spd*max_spd
 end

 -- move
 ship.x+=ship.dx
 ship.y+=ship.dy

 -- update tow cable
 if ship.cable_out and ship.cable_tgt then
  local tgt=ship.cable_tgt
  local cdx=ship.x-tgt.x
  local cdy=ship.y-tgt.y
  local dist
  if abs(cdx)>40 or abs(cdy)>40 then
   dist=41
  else
   dist=sqrt(cdx*cdx+cdy*cdy)
  end
  if dist>40 then
   -- cable snaps
   ship.cable_out=false
   ship.cable_tgt=nil
   sfx(5)
  else
   -- drag target toward ship
   tgt.dx+=(cdx/dist)*0.02
   tgt.dy+=(cdy/dist)*0.02
  end
 end

 ship.fuel=max(0,ship.fuel)

 -- update camera: snap to ship + look ahead
 -- combine facing direction and velocity
 local look_ang=20
 local look_vel=15
 local tx=cos(ship.ang)*look_ang+ship.dx*look_vel
 local ty=sin(ship.ang)*look_ang+ship.dy*look_vel
 cam_ox+=(tx-cam_ox)*0.03
 cam_oy+=(ty-cam_oy)*0.03
 cam_x=ship.x-64+cam_ox
 cam_y=ship.y-64+cam_oy
end

function draw_ship()
 if not ship.alive then return end

 local x=ship.x
 local y=ship.y
 local a=ship.ang
 local ca=cos(a)
 local sa=sin(a)

 -- ship body (triangle)
 local nx=x+ca*5
 local ny=y+sa*5
 local lx=x+cos(a+0.35)*4
 local ly=y+sin(a+0.35)*4
 local rx=x+cos(a-0.35)*4
 local ry=y+sin(a-0.35)*4

 -- damage flash
 local sc1=7
 local sc2=12
 if ship.dmg_timer>0 and flr(ship.dmg_timer/2)%2==1 then
  sc1=8
  sc2=8
 end
 line(nx,ny,lx,ly,sc1)
 line(nx,ny,rx,ry,sc1)
 line(lx,ly,rx,ry,sc2)

 -- thrust flames
 if ship.thrust_f>0 then
  local bx=x-ca*(5+rnd(3))
  local by=y-sa*(5+rnd(3))
  line(x-ca*3,y-sa*3,bx,by,9+flr(rnd(2)))
 end
 if ship.thrust_b>0 then
  local fx=x+ca*(4+rnd(2))
  local fy=y+sa*(4+rnd(2))
  pset(fx,fy,9)
 end
 if ship.thrust_l>0 then
  local sx=x+cos(a-0.25)*(4+rnd(2))
  local sy=y+sin(a-0.25)*(4+rnd(2))
  pset(sx,sy,9)
 end
 if ship.thrust_r>0 then
  local sx=x+cos(a+0.25)*(4+rnd(2))
  local sy=y+sin(a+0.25)*(4+rnd(2))
  pset(sx,sy,9)
 end

 -- tow cable
 if ship.cable_out and ship.cable_tgt then
  local tgt=ship.cable_tgt
  line(x,y,tgt.x,tgt.y,6)
 end
end

function ship_hit()
 if ship.dmg_timer>0 then return end
 ship.hp-=1
 ship.dmg_timer=30
 if ship.hp<=0 then
  ship_die()
 else
  -- damage sparks
  for i=1,4 do
   add(particles,{
    x=ship.x,y=ship.y,
    dx=rnd(1)-0.5,dy=rnd(1)-0.5,
    life=10+rnd(5),
    c=8
   })
  end
  sfx(0)
 end
end

function ship_die()
 ship.alive=false
 -- explosion particles
 for i=1,12 do
  add(particles,{
   x=ship.x,y=ship.y,
   dx=rnd(2)-1,dy=rnd(2)-1,
   life=20+rnd(15),
   c=rnd()>0.5 and 9 or 10
  })
 end
 sfx(1)
 fail_timer=60
end

-------------------------------
-- projectiles
-------------------------------
bullets={}

function fire_laser()
 ship.ammo-=1
 local ca=cos(ship.ang)
 local sa=sin(ship.ang)
 add(bullets,{
  x=ship.x+ca*6,
  y=ship.y+sa*6,
  dx=ca*3+ship.dx,
  dy=sa*3+ship.dy,
  life=30
 })
 sfx(2,1)
end

function update_bullets()
 for b in all(bullets) do
  b.x+=b.dx
  b.y+=b.dy
  b.life-=1
  if b.life<=0 then
   del(bullets,b)
   if #bullets==0 then sfx(-1,1) end
  else
   -- check obstacle collision
   for ob in all(obstacles) do
    local ddx=b.x-ob.x
    local ddy=b.y-ob.y
    if abs(ddx)<=ob.r and abs(ddy)<=ob.r and ddx*ddx+ddy*ddy<ob.r*ob.r then
     ob.hp-=1
     del(bullets,b)
     if #bullets==0 then sfx(-1,1) end
     if ob.hp<=0 then
      -- destroy obstacle
      for i=1,8 do
       add(particles,{
        x=ob.x,y=ob.y,
        dx=rnd(2)-1,dy=rnd(2)-1,
        life=15+rnd(10),
        c=rnd()>0.5 and 5 or 6
       })
      end
      del(obstacles,ob)
      sfx(4)
     else
      sfx(0)
     end
     break
    end
   end
   -- check mine collision
   for m in all(mines) do
    if not m.det then
     local mdx=b.x-m.x
     local mdy=b.y-m.y
     if abs(mdx)<=4 and abs(mdy)<=4 then
      m.det=3
      del(bullets,b)
      if #bullets==0 then sfx(-1,1) end
      break
     end
    end
   end
  end
 end
end

function draw_bullets()
 for b in all(bullets) do
  pset(b.x,b.y,11)
  pset(b.x-b.dx*0.3,b.y-b.dy*0.3,3)
 end
end

-------------------------------
-- tow cable
-------------------------------
function toggle_cable()
 if ship.cable_out then
  ship.cable_out=false
  ship.cable_tgt=nil
  sfx(3)
  return
 end
 -- find nearest debris
 local best,bd=nil,40
 for d in all(debris) do
  local ddx=ship.x-d.x
  local ddy=ship.y-d.y
  if abs(ddx)<=bd and abs(ddy)<=bd then
   local dist=sqrt(ddx*ddx+ddy*ddy)
   if dist<bd then
    best=d
    bd=dist
   end
  end
 end
 if best then
  ship.cable_out=true
  ship.cable_tgt=best
  sfx(3)
 end
end

-------------------------------
-- obstacles & debris
-------------------------------
obstacles={}
debris={}
drop_zone=nil
fuel_pods={}

function update_obstacles()
 for ob in all(obstacles) do
  ob.x+=ob.dx or 0
  ob.y+=ob.dy or 0
  -- check ship collision
  if ship.alive then
   local ddx=ship.x-ob.x
   local ddy=ship.y-ob.y
   local hr=ob.r+3
   if abs(ddx)<=hr and abs(ddy)<=hr and ddx*ddx+ddy*ddy<hr*hr then
    ship_hit()
   end
  end
 end
end

function update_debris()
 for d in all(debris) do
  d.x+=(d.dx or 0)
  d.y+=(d.dy or 0)
  d.dx=(d.dx or 0)*friction
  d.dy=(d.dy or 0)*friction
  -- check drop zone
  if drop_zone then
   local ddx=d.x-drop_zone.x
   local ddy=d.y-drop_zone.y
   if abs(ddx)<=drop_zone.r and abs(ddy)<=drop_zone.r and ddx*ddx+ddy*ddy<drop_zone.r*drop_zone.r then
    d.collected=true
    del(debris,d)
    if ship.cable_tgt==d then
     ship.cable_out=false
     ship.cable_tgt=nil
    end
    sfx(4)
   end
  end
 end
end

function draw_obstacles()
 for ob in all(obstacles) do
  circ(ob.x,ob.y,ob.r,5)
  -- jagged asteroid look
  for i=0,5 do
   local a=i/6
   local r2=ob.r*0.7+rnd(ob.r*0.3)
   pset(ob.x+cos(a)*r2,ob.y+sin(a)*r2,6)
  end
 end
end

function draw_debris()
 for d in all(debris) do
  rectfill(d.x-2,d.y-2,d.x+2,d.y+2,6)
  rect(d.x-2,d.y-2,d.x+2,d.y+2,13)
 end
 if drop_zone then
  local dz=drop_zone
  circ(dz.x,dz.y,dz.r,11)
  circ(dz.x,dz.y,dz.r-1,3)
  print("drop",dz.x-8,dz.y-3,11)
 end
end

-------------------------------
-- fuel pods
-------------------------------
function update_fuel_pods()
 for f in all(fuel_pods) do
  local ddx=ship.x-f.x
  local ddy=ship.y-f.y
  if abs(ddx)<=8 and abs(ddy)<=8 and ddx*ddx+ddy*ddy<64 then
   ship.fuel=min(100,ship.fuel+f.amt)
   del(fuel_pods,f)
   sfx(4)
  end
 end
end

function draw_fuel_pods()
 for f in all(fuel_pods) do
  local pulse=sin(frame/20)*1
  circfill(f.x,f.y,3+pulse,11)
  circfill(f.x,f.y,2+pulse,3)
  print("+",f.x-2,f.y-2,7)
 end
end

-------------------------------
-- ammo pods
-------------------------------
function update_ammo_pods()
 for a in all(ammo_pods) do
  local ddx=ship.x-a.x
  local ddy=ship.y-a.y
  if abs(ddx)<=8 and abs(ddy)<=8 and ddx*ddx+ddy*ddy<64 then
   ship.ammo+=a.amt
   del(ammo_pods,a)
   sfx(4)
  end
 end
end

function draw_ammo_pods()
 for a in all(ammo_pods) do
  local pulse=sin(frame/20)*1
  circfill(a.x,a.y,3+pulse,8)
  circfill(a.x,a.y,2+pulse,2)
  print("a",a.x-2,a.y-2,7)
 end
end

-------------------------------
-- explosion rings
-------------------------------
rings={}

function update_rings()
 for r in all(rings) do
  r.r+=1.5
  r.life-=1
  if r.life<=0 then del(rings,r) end
 end
end

function draw_rings()
 for r in all(rings) do
  local c=r.life>5 and 9 or 5
  circ(r.x,r.y,r.r,c)
 end
end

-------------------------------
-- gravity wells
-------------------------------
grav_wells={}

function update_grav_wells()
 for g in all(grav_wells) do
  local ddx=g.x-ship.x
  local ddy=g.y-ship.y
  if abs(ddx)>g.pull_r or abs(ddy)>g.pull_r then
   -- too far, no effect
  else
   local dist=sqrt(ddx*ddx+ddy*ddy)
   if dist<g.kill_r and ship.alive then
    ship_die()
   elseif dist<g.pull_r and dist>1 then
    local f=g.str/dist
    ship.dx+=ddx/dist*f
    ship.dy+=ddy/dist*f
   end
  end
 end
end

function draw_grav_wells()
 for g in all(grav_wells) do
  -- planet/black hole
  circfill(g.x,g.y,g.kill_r,g.c or 0)
  circ(g.x,g.y,g.kill_r,g.oc or 1)
  -- gravity field rings
  for i=1,3 do
   local r=g.kill_r+i*(g.pull_r-g.kill_r)/4
   local pulse=sin(frame/40+i*0.3)*0.5
   circ(g.x,g.y,r+pulse,1)
  end
 end
end

-------------------------------
-- mines
-------------------------------
mines={}

function update_mines()
 for m in all(mines) do
  if m.det then
   m.det-=1
   if m.det<=0 then
    explode_mine(m)
   end
  else
   -- ship proximity trigger
   if ship.alive then
    local ddx=ship.x-m.x
    local ddy=ship.y-m.y
    if abs(ddx)<=5 and abs(ddy)<=5 then
     m.det=2
    end
   end
  end
 end
end

function explode_mine(m)
 -- explosion particles
 for i=1,6 do
  add(particles,{
   x=m.x,y=m.y,
   dx=rnd(2)-1,dy=rnd(2)-1,
   life=10+rnd(8),
   c=rnd()>0.5 and 9 or 10
  })
 end
 -- damage ship if close
 local ddx=ship.x-m.x
 local ddy=ship.y-m.y
 if abs(ddx)<=m.blast and abs(ddy)<=m.blast then
  local dist=sqrt(ddx*ddx+ddy*ddy)
  if dist<m.blast then
   ship_hit()
   -- push ship away
   if dist>1 then
    ship.dx+=ddx/dist*0.8
    ship.dy+=ddy/dist*0.8
   end
  end
 end
 -- chain: trigger nearby mines
 local cr=m.blast*1.5
 for m2 in all(mines) do
  if m2!=m and not m2.det then
   local dx2=m2.x-m.x
   local dy2=m2.y-m.y
   if abs(dx2)<=cr and abs(dy2)<=cr then
    local d2=sqrt(dx2*dx2+dy2*dy2)
    if d2<cr then
     m2.det=flr(d2/3)+1
    end
   end
  end
 end
 add(rings,{x=m.x,y=m.y,r=2,life=flr(m.blast/1.5)})
 del(mines,m)
 sfx(4)
end

function draw_mines()
 for m in all(mines) do
  if m.det then
   -- flashing when about to explode
   local c=flr(frame/2)%2==0 and 8 or 9
   circfill(m.x,m.y,3,c)
  else
   circfill(m.x,m.y,2,0)
   circ(m.x,m.y,2,5)
   pset(m.x,m.y,8)
  end
 end
end

-------------------------------
-- shield pickups
-------------------------------
shield_pods={}

function update_shield_pods()
 for s in all(shield_pods) do
  local ddx=ship.x-s.x
  local ddy=ship.y-s.y
  if abs(ddx)<=8 and abs(ddy)<=8 and ddx*ddx+ddy*ddy<64 then
   ship.hp=min(3,ship.hp+1)
   del(shield_pods,s)
   sfx(4)
  end
 end
end

function draw_shield_pods()
 for s in all(shield_pods) do
  local pulse=sin(frame/20)*1
  circfill(s.x,s.y,3+pulse,12)
  circfill(s.x,s.y,2+pulse,1)
  print("\x97",s.x-2,s.y-2,7)
 end
end

-------------------------------
-- particles
-------------------------------
particles={}

function update_particles()
 for p in all(particles) do
  p.x+=p.dx
  p.y+=p.dy
  p.dx*=0.95
  p.dy*=0.95
  p.life-=1
  if p.life<=0 then
   del(particles,p)
  end
 end
end

function draw_particles()
 for p in all(particles) do
  pset(p.x,p.y,p.c)
 end
end

-------------------------------
-- landing zone
-------------------------------
land={}

function diff_radius(r)
 return r*split"1,0.85,0.7,0.55"[difficulty+1]
end

function diff_hp(hp)
 return hp*split"1,1,2,3"[difficulty+1]
end

function init_land(x,y,r)
 land={x=x,y=y,r=diff_radius(r or 8)}
end

function check_landing()
 if not ship.alive then return false end
 local ddx=ship.x-land.x
 local ddy=ship.y-land.y
 -- early out: avoid overflow
 -- on 16.16 fixed point
 if abs(ddx)>land.r or abs(ddy)>land.r then return false end
 local dist=sqrt(ddx*ddx+ddy*ddy)
 local spd=sqrt(ship.dx*ship.dx+ship.dy*ship.dy)
 -- must be close and slow
 if dist<land.r and spd<0.3 then
  return true
 end
 return false
end

function draw_land()
 local lz=land
 local pulse=sin(frame/30)*2
 circ(lz.x,lz.y,lz.r+pulse,11)
 circ(lz.x,lz.y,lz.r*0.6+pulse,3)
 print("land",lz.x-8,lz.y-3,11)
end

-------------------------------
-- stars background
-------------------------------
stars={}

function init_stars()
 stars={}
 for i=1,50 do
  local spd=0.1+rnd(0.4)
  add(stars,{
   x=rnd(128),y=rnd(128),
   spd=spd,
   c=spd>0.3 and 7 or (spd>0.2 and 6 or 5),
   blink=rnd(1)
  })
 end
 -- space dust
 dust={}
 for i=1,12 do
  add(dust,{
   x=rnd(128),y=rnd(128),
   dx=rnd(0.3)-0.15,
   dy=rnd(0.3)-0.15,
   life=rnd(1)
  })
 end
end

star_dir=0 -- 0=left, 1=right

function update_stars()
 local dir=star_dir==0 and -1 or 1
 for s in all(stars) do
  s.x+=s.spd*dir
  if s.x<0 then
   s.x=128
   s.y=rnd(128)
  elseif s.x>128 then
   s.x=0
   s.y=rnd(128)
  end
 end
end

function draw_stars()
 for s in all(stars) do
  -- parallax: faster stars move more with camera
  local px=(s.x-cam_x*s.spd)%128
  local py=(s.y-cam_y*s.spd)%128
  -- twinkle: some stars blink
  s.blink+=0.02
  if s.blink>1 then s.blink-=1 end
  local bright=s.c
  if s.c==7 and sin(s.blink)>0.3 then
   bright=6
  elseif s.c==6 and sin(s.blink)>0.4 then
   bright=5
  end
  pset(px,py,bright)
 end
 -- space dust
 for d in all(dust) do
  d.x+=d.dx
  d.y+=d.dy
  d.life+=0.01
  if d.life>1 then d.life-=1 end
  local px=(d.x-cam_x*0.2)%128
  local py=(d.y-cam_y*0.2)%128
  if d.life>0.5 then
   pset(px,py,1)
  end
 end
end

-------------------------------
-- levels
-------------------------------
function reset_world()
 obstacles={}
 debris={}
 bullets={}
 drop_zone=nil
 fuel_pods={}
 ammo_pods={}
 mines={}
 grav_wells={}
 shield_pods={}
 rings={}
end

levels={
 -- level 1: straight ahead
 {
  title="straight ahead",
  brief="nAVIGATE FROM POINT a\nTO THE LANDING ZONE IN\nA STRAIGHT LINE.\n\nsIMPLE, RIGHT?\n\ns.c.a.m. BELIEVES IN YOU.\nmOSTLY.",
  has_fwd=true,
  has_rot=false,
  has_items=false,
  has_cable=false,
  setup=function()
   init_ship(20,64,0,30)
   init_land(250,64)
   reset_world()
   ship.ammo=0
  end
 },
 -- level 2: turn around
 {
  title="turn around",
  brief="tHE LANDING ZONE ISN'T\nALWAYS IN FRONT OF YOU.\n\ntIME TO LEARN HOW TO\nTURN.\n\ntRY NOT TO GET DIZZY.",
  has_fwd=true,
  has_rot=true,
  has_items=false,
  has_cable=false,
  setup=function()
   init_ship(64,200,0,40)
   init_land(200,40)
   reset_world()
   ship.ammo=0
  end
 },
 -- level 3: clear the path
 {
  title="clear the path",
  brief="sOMETIMES THE TRASH IS\nIN THE WAY.\n\ntHAT'S WHY WE GAVE YOU\nA LASER.\n\npLEASE DON'T POINT IT\nAT COWORKERS.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=false,
  setup=function()
   init_ship(20,100,0,50)
   init_land(280,100)
   reset_world()
   obstacles={
    {x=150,y=100,r=10,hp=diff_hp(3),dx=0,dy=0}
   }
   ship.ammo=10
  end
 },
 -- level 4: tow the line
 {
  title="tow the line",
  brief="nOT EVERYTHING IS TRASH.\nsOME THINGS ARE VALUABLE\nTRASH.\n\nuSE THE TOW CABLE TO\nHAUL DEBRIS TO THE\nCOLLECTION ZONE.\n\ntHEN LAND SAFELY.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=true,
  setup=function()
   init_ship(20,200,0,55)
   init_land(280,40)
   reset_world()
   obstacles={
    {x=180,y=120,r=8,hp=diff_hp(2),dx=0,dy=0}
   }
   debris={
    {x=100,y=80,dx=0,dy=0,collected=false}
   }
   drop_zone={x=250,y=200,r=diff_radius(14)}
  end
 },
 -- level 5: bulk collection
 {
  title="bulk order",
  brief="s.c.a.m. HAS RECEIVED A\nBULK ORDER.\n\ncOLLECT ALL CARGO AND\nDELIVER TO THE DROP ZONE.\n\nOVERTIME IS NOT\nCOMPENSATED.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=true,
  setup=function()
   init_ship(20,150,0,65)
   init_land(350,150)
   reset_world()
   obstacles={
    {x=120,y=80,r=8,hp=diff_hp(2),dx=0,dy=0},
    {x=250,y=200,r=10,hp=diff_hp(3),dx=0,dy=0}
   }
   debris={
    {x=80,y=50,dx=0,dy=0,collected=false},
    {x=180,y=250,dx=0,dy=0,collected=false},
    {x=300,y=80,dx=0,dy=0,collected=false}
   }
   drop_zone={x=200,y=150,r=diff_radius(16)}
   ship.ammo=15
  end
 },
 -- level 6: long haul
 {
  title="the long haul",
  brief="tHE LANDING ZONE IS FAR.\nvERY FAR.\n\nyOU WON'T HAVE ENOUGH\nFUEL. bUT S.C.A.M. LEFT\nSOME FUEL PODS ALONG\nTHE WAY.\n\npROBABLY.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=false,
  setup=function()
   init_ship(20,300,0,30)
   init_land(500,50)
   reset_world()
   obstacles={
    {x=150,y=200,r=12,hp=diff_hp(2),dx=0,dy=0},
    {x=350,y=150,r=10,hp=diff_hp(3),dx=0,dy=0}
   }
   fuel_pods={
    {x=100,y=250,amt=20},
    {x=250,y=180,amt=20},
    {x=400,y=100,amt=15}
   }
  end
 },
 -- level 7: minefield
 {
  title="minefield",
  brief="tHE DIRECT ROUTE IS\nMINED. sOMEONE LEFT\nEXPLOSIVES EVERYWHERE.\n\nwATCH YOUR STEP.\nOR YOUR THRUST.\n\nwE ADDED SHIELDS.\nyOU'RE WELCOME.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=false,
  setup=function()
   init_ship(20,150,0,50)
   init_land(350,150)
   reset_world()
   mines={
    {x=90,y=140,blast=20},
    {x=105,y=155,blast=20},
    {x=115,y=135,blast=20},
    {x=200,y=150,blast=20},
    {x=215,y=165,blast=20},
    {x=225,y=140,blast=20},
    {x=290,y=145,blast=20}
   }
   ammo_pods={
    {x=160,y=100,amt=5}
   }
   shield_pods={
    {x=150,y=190},
    {x=260,y=110}
   }
   ship.ammo=5
  end
 },
 -- level 8: gravity assist
 {
  title="gravity assist",
  brief="a ROGUE PLANET BLOCKS\nYOUR PATH. iTS GRAVITY\nIS STRONG.\n\nuSE IT TO YOUR\nADVANTAGE. oR DON'T.\n\ns.c.a.m. HAS INSURANCE.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=true,
  setup=function()
   init_ship(20,200,0,45)
   init_land(400,80)
   reset_world()
   obstacles={
    {x=280,y=100,r=6,hp=diff_hp(2),dx=0,dy=0.5},
    {x=180,y=200,r=6,hp=diff_hp(2),dx=0,dy=-0.5}
   }
   debris={
    {x=120,y=260,dx=0,dy=0,collected=false}
   }
   drop_zone={x=350,y=180,r=diff_radius(14)}
   fuel_pods={
    {x=300,y=250,amt=15}
   }
   grav_wells={
    {x=220,y=150,kill_r=8,pull_r=80,str=0.08,c=2,oc=4}
   }
   shield_pods={
    {x=100,y=140}
   }
  end
 },
 -- level 9: moving day
 {
  title="moving day",
  brief="fLOATING ASTEROIDS\nEVERYWHERE. tHEY DON'T\nCARE ABOUT YOU.\n\nDODGE, SHOOT, OR BOTH.\n\npERFORMANCE REVIEW IS\nNEXT WEEK.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=false,
  setup=function()
   init_ship(20,150,0,50)
   init_land(450,150)
   reset_world()
   obstacles={
    {x=100,y=80,r=10,hp=diff_hp(3),dx=0.8,dy=0.4},
    {x=180,y=220,r=8,hp=diff_hp(2),dx=-0.6,dy=-0.7},
    {x=260,y=100,r=12,hp=diff_hp(4),dx=0.5,dy=0.9},
    {x=340,y=200,r=8,hp=diff_hp(2),dx=-0.7,dy=0.5}
   }
   fuel_pods={
    {x=200,y=150,amt=15},
    {x=350,y=100,amt=15}
   }
   ammo_pods={
    {x=150,y=150,amt=5}
   }
   shield_pods={
    {x=300,y=180}
   }
   ship.ammo=12
  end
 },
 -- level 10: final exam
 {
  title="final exam",
  brief="tHIS IS IT. eVERYTHING\nYOU'VE LEARNED.\n\nmINES. gRAVITY. aSTEROIDS.\ncARGO. aND A VERY LONG\nWAY TO GO.\n\ngOOD LUCK, RECRUIT.",
  has_fwd=true,
  has_rot=true,
  has_items=true,
  has_cable=true,
  setup=function()
   init_ship(20,300,0,40)
   init_land(550,60)
   reset_world()
   obstacles={
    {x=150,y=250,r=10,hp=diff_hp(3),dx=0.6,dy=-0.5},
    {x=350,y=180,r=8,hp=diff_hp(2),dx=-0.5,dy=0.4}
   }
   debris={
    {x=100,y=200,dx=0,dy=0,collected=false},
    {x=300,y=250,dx=0,dy=0,collected=false}
   }
   drop_zone={x=400,y=250,r=diff_radius(14)}
   fuel_pods={
    {x=120,y=150,amt=15},
    {x=280,y=100,amt=15},
    {x=450,y=200,amt=15}
   }
   mines={
    {x=200,y=210,blast=20},
    {x=380,y=130,blast=20},
    {x=480,y=90,blast=20}
   }
   grav_wells={
    {x=250,y=150,kill_r=8,pull_r=70,str=0.06,c=2,oc=4}
   }
   ammo_pods={
    {x=350,y=100,amt=5}
   }
   shield_pods={
    {x=200,y=120},
    {x=420,y=170}
   }
  end
 }
}

-------------------------------
-- audio
-------------------------------
function stop_all_sfx()
 for i=0,3 do sfx(-1,i) end
end

-------------------------------
-- outlined text
-------------------------------
function cprint(t,y,c)
 print(t,64-#t*2,y,c)
end

function draw_hiscores(y0,sp)
 local dlet={"i","e","m","c"}
 print("name",24,y0,6)
 print("score",48,y0,6)
 print("lv",80,y0,6)
 print("df",100,y0,6)
 line(20,y0+7,108,y0+7,5)
 for i=1,min(#hi_names,5) do
  local y=y0+10+(i-1)*sp
  local c=i==1 and 10 or 7
  print(hi_names[i],24,y,c)
  print(tostr(hi_scores[i]),48,y,c)
  print(tostr(hi_levels[i]).."/"..max_lvl,76,y,c)
  print(dlet[flr(hi_diffs[i])%4+1],100,y,c)
 end
end

function coprint(t,y,c,oc)
 local x=64-#t*2
 print(t,x-1,y,oc)
 print(t,x+1,y,oc)
 print(t,x,y-1,oc)
 print(t,x,y+1,oc)
 print(t,x,y,c)
end

-------------------------------
-- chrome panel
-------------------------------
function draw_panel(x0,y0,x1,y1)
 line(x0,y0,x1,y0,7)
 line(x0,y0,x0,y1,7)
 line(x0+1,y1,x1,y1,12)
 line(x1,y0+1,x1,y1,12)
 line(x0+1,y0+1,x1-1,y0+1,12)
 line(x0+1,y0+1,x0+1,y1-1,12)
 line(x0+1,y1-1,x1-1,y1-1,7)
 line(x1-1,y0+1,x1-1,y1-1,7)
 line(x0+2,y0+2,x1-2,y0+2,0)
 line(x0+2,y0+2,x0+2,y1-2,0)
 rectfill(x0+3,y0+3,x1-2,y1-2,1)
end

-------------------------------
-- hud
-------------------------------
function draw_hud()
 -- fuel bar (left)
 local fw=flr(ship.fuel*0.4)
 local fc=11
 if ship.fuel<30 then fc=8 end
 if ship.fuel<15 then fc=flr(frame/4)%2==0 and 8 or 0 end
 rectfill(2,2,2+40,5,0)
 rectfill(2,2,2+fw,5,fc)
 rect(2,2,2+40,5,6)
 print("fuel",2,8,6)

 -- hull bar (right)
 local hw=flr(ship.hp/3*40)
 local hc=8
 if ship.hp<=1 then hc=flr(frame/4)%2==0 and 8 or 0 end
 rectfill(85,2,125,5,0)
 rectfill(125-hw,2,125,5,hc)
 rect(85,2,125,5,6)
 print("hull",112,8,6)

 -- speed (center)
 local spd=sqrt(ship.dx*ship.dx+ship.dy*ship.dy)
 local sc=11
 if spd>1.5 then sc=8 end
 print("spd:"..flr(spd*100)/100,48,2,sc)

 -- item display (center)
 local lv=levels[lvl]
 if lv.has_items then
  local iname="laser"
  local ic=8
  if lv.has_cable then
   if ship.item==2 then
    iname="cable"
    ic=6
   end
  end
  print("["..iname.."]",48,8,ic)
  if ship.item==1 then
   print("ammo:"..ship.ammo,48,14,7)
  end
 end
end

-------------------------------
-- input helpers
-------------------------------
-- tracks "press then release" cycle
-- returns true only on the frame
-- all buttons are released after
-- at least one was pressed
wait_release=false

function any_btn()
 return btn(0) or btn(1) or btn(2) or btn(3) or btn(4) or btn(5)
end

function any_btnp()
 if wait_release then
  if not any_btn() then
   wait_release=false
   return true
  end
  return false
 else
  if any_btn() then
   wait_release=true
  end
  return false
 end
end

function reset_btnp()
 wait_release=false
end

-------------------------------
-- game state management
-------------------------------
intro_timer=0
intro_cycle=0
intro_page=0
brief_timer=0
success_timer=0
fail_timer=0
land_timer=0

-- highscore
hi_names={}
hi_scores={}
hi_levels={}
hi_diffs={}
name_chars={1,1,1} -- a=1
name_pos=1

function load_scores()
 hi_names={}
 hi_scores={}
 hi_levels={}
 hi_diffs={}
 for i=0,4 do
  local c1=dget(i*6)
  local c2=dget(i*6+1)
  local c3=dget(i*6+2)
  local sc=dget(i*6+3)
  local lv=dget(i*6+4)
  local df=dget(i*6+5)
  if sc>0 then
   add(hi_names,chr(64+c1)..chr(64+c2)..chr(64+c3))
   add(hi_scores,sc)
   add(hi_levels,lv)
   add(hi_diffs,df)
  end
 end
end

function save_scores()
 for i=1,min(#hi_names,5) do
  local n=hi_names[i]
  dset((i-1)*6,ord(n,1)-64)
  dset((i-1)*6+1,ord(n,2)-64)
  dset((i-1)*6+2,ord(n,3)-64)
  dset((i-1)*6+3,hi_scores[i])
  dset((i-1)*6+4,hi_levels[i])
  dset((i-1)*6+5,hi_diffs[i])
 end
end

function insert_score(name,sc,lv)
 local pos=#hi_names+1
 for i=1,#hi_names do
  if sc>hi_scores[i] then
   pos=i
   break
  end
 end
 -- insert at position
 local nn={}
 local ns={}
 local nl={}
 local nd={}
 for i=1,pos-1 do
  add(nn,hi_names[i])
  add(ns,hi_scores[i])
  add(nl,hi_levels[i])
  add(nd,hi_diffs[i])
 end
 add(nn,name)
 add(ns,sc)
 add(nl,lv)
 add(nd,difficulty)
 for i=pos,#hi_names do
  add(nn,hi_names[i])
  add(ns,hi_scores[i])
  add(nl,hi_levels[i])
  add(nd,hi_diffs[i])
 end
 hi_names=nn
 hi_scores=ns
 hi_levels=nl
 hi_diffs=nd
 -- cap at 5
 while #hi_names>5 do
  hi_names[#hi_names]=nil
  hi_scores[#hi_scores]=nil
  hi_levels[#hi_levels]=nil
  hi_diffs[#hi_diffs]=nil
 end
 save_scores()
end

-------------------------------
-- state functions
-------------------------------
function start_level()
 levels[lvl].setup()
 particles={}
 land_timer=0
 fail_timer=0
 warn_scroll=-1
 warn_text=""
 cam_ox=0
 cam_oy=0
 cam_x=ship.x-64
 cam_y=ship.y-64
 state=st_play
end

function calc_score()
 local base=ship.fuel*10+lvl*50
 return flr(base*split"1,2,4,8"[difficulty+1])
end

-------------------------------
-- main pico-8 callbacks
-------------------------------
function _init()
 cartdata("scrap_scam_2126")
 --cheat: uncomment to clear all save data
 --for i=0,63 do dset(i,0) end
 init_stars()
 load_scores()
 reverse_rot=dget(30)!=1 -- default true unless explicitly set to 1 (direct)
 difficulty=flr(dget(31))%4
 star_dir=reverse_rot and 0 or 1
 state=st_intro
 intro_timer=0
 intro_cycle=0
 intro_page=0
 --cheat: uncomment to skip to a level
 --state=st_brief lvl=7
end

prev_state=-1

function _update60()
 frame+=1

 -- reset input on state change
 if state!=prev_state then
  reset_btnp()
  prev_state=state
 end

 if state==st_intro then
  update_intro()
 elseif state==st_brief then
  update_brief()
 elseif state==st_play then
  update_play()
 elseif state==st_success then
  update_success()
 elseif state==st_fail then
  update_fail()
 elseif state==st_namein then
  update_namein()
 elseif state==st_scores then
  update_scores()
 end
end

function _draw()
 cls(0)
 draw_stars()

 if state==st_intro then
  draw_intro()
 elseif state==st_brief then
  draw_brief()
 elseif state==st_play then
  draw_play()
 elseif state==st_success then
  draw_success()
 elseif state==st_fail then
  draw_fail()
 elseif state==st_namein then
  draw_namein()
 elseif state==st_scores then
  draw_scores()
 end
end

-------------------------------
-- intro state
-------------------------------
scroll_pos=0

function update_intro()
 if intro_timer<200 then intro_timer+=1 end
 if intro_timer>=200 then
  intro_cycle+=1
  if intro_cycle>=300 then
   -- cycle: 0=title -> 1=scores -> 2=credits -> 0
   if intro_page==0 and #hi_names>0 then
    intro_page=1
   elseif intro_page==0 then
    intro_page=2
   elseif intro_page==1 then
    intro_page=2
   else
    intro_page=0
   end
   intro_cycle=0
  end
 end
 scroll_pos+=0.8
 if scroll_pos>30000 then scroll_pos=0 end
 update_stars()
 if intro_timer>60 then
  -- any input resets cycle timer and shows menu
  if any_btnp() then
   intro_cycle=0
   if intro_page!=0 then
    intro_page=0
   end
  end
  -- menu navigation
  if intro_page==0 and btnp(2) then
   menu_sel=max(0,menu_sel-1)
   sfx(3)
  end
  if intro_page==0 and btnp(3) then
   menu_sel=min(1,menu_sel+1)
   sfx(3)
  end
  -- change selected option
  if intro_page==0 and (btnp(0) or btnp(1)) then
   if menu_sel==0 then
    reverse_rot=not reverse_rot
    star_dir=reverse_rot and 0 or 1
    dset(30,reverse_rot and 0 or 1)
   elseif menu_sel==1 then
    difficulty=(difficulty+(btnp(1) and 1 or -1))%4
    dset(31,difficulty)
   end
   sfx(3)
  end
 end
 -- start game
 if intro_timer>60 and (btnp(4) or btnp(5)) then
  sfx(7)
  lvl=1
  total_score=0
  state=st_brief
  brief_timer=0
 end
end

function draw_intro()
 -- logo
 local c=7
 if intro_timer<30 then
  c=flr(intro_timer/4)%2==0 and 7 or 0
 end

 -- ascii art (all at x=14 for alignment)
 print(" ___  ___ ___    _   ___",14,10,c)
 print("/ __|/ __| _ \\  /_\\ | _ \\")
 print("\\__ \\ (_||   / / _ \\|  _/")
 print("|___/\\___|_|_\\/_/ \\_\\_|")

 if intro_page==1 then
  -- show highscores
  draw_hiscores(48,10)
 elseif intro_page==2 then
  -- credits
  cprint("credits",36,13)
  line(20,44,108,44,5)
  cprint("brainstorming",48,6)
  print("  hENRIK eNGEL",36,56,7)
  print("  iDA pETTERSEN")
  print("  mICKAEL pOINTIER")
  print("  sOREN jENSEN")
  print("  tHOMAS mUNDAL")
  line(20,87,108,87,5)
  print("cODE, gFX, sFX",36,91,6)
  print("  cLAUDE oPUS",36,97,7)
  print("pROMPTING & tESTING",36,105,6)
  print("  mICKAEL pOINTIER",36,111,7)
 else
  if intro_timer>80 then
   print("space cleaning rules",24,36,13)
   print("and procedures",36,44,13)
   if intro_timer>160 then
     print("9TH eDITION",42,51,14)
    end
  end
 end

 if intro_timer>60 and intro_page==0 then
  cprint("sETTINGS:",68,6)
  -- rotation option
  local rc=menu_sel==0 and 7 or 5
  local rtxt="rotation: "..(reverse_rot and "steering" or "direct")
  local rx=64-#rtxt*2
  print(rtxt,rx,79,rc)
  if menu_sel==0 then
   spr(2,rx-10,78)
   spr(3,rx+#rtxt*4+2,78)
  end
  -- difficulty option
  local dc=menu_sel==1 and 7 or 5
  local dtxt="difficulty: "..diff_names[difficulty+1]
  local ddx=64-#dtxt*2
  print(dtxt,ddx,89,dc)
  if menu_sel==1 then
   spr(2,ddx-10,88)
   spr(3,ddx+#dtxt*4+2,88)
  end
 end
 if intro_timer>60 and flr(frame/30)%2==0 then
  coprint("press z/x",114,11,0)
 end

 -- scrolling legal ticker
 if intro_timer>60 then
  local scroll_txt="(c) 2126 sPACE cLEANING aDVANCED mANAGEMENT (s.c.a.m) - tHIS TRAINING SIMULATOR IS PROVIDED EXCLUSIVELY TO sPACE cLEANERS uNLICENSED mEMBERS (s.c.u.m.) FOR CERTIFICATION PURPOSES ONLY. aNY UNAUTHORIZED USE, DUPLICATION, REVERSE ENGINEERING, INTELLECTUAL PROPERTY THEFT, FUN, ENJOYMENT OR DISTRIBUTION OF THIS PRODUCT CAN AND WILL RESULT IN DISCIPLINARY PROCEDURES, DEMOTION TO ASTEROID SCRUBBING DUTY, AND/OR EJECTION INTO THE NEAREST BLACK HOLE. S.C.A.M. ACCEPTS NO LIABILITY FOR INJURIES, EXISTENTIAL DREAD, OR SPONTANEOUS COMBUSTION OCCURRING DURING TRAINING. aLL COMPLAINTS SHOULD BE FILED IN TRIPLICATE AND LAUNCHED INTO THE SUN.                                   "
  local tw=#scroll_txt*4
  local scroll_x=128-scroll_pos%tw
  print(scroll_txt,scroll_x,122,5)
 end
end

-------------------------------
-- briefing state
-------------------------------
function update_brief()
 brief_timer+=1
 if brief_timer>30 and any_btnp() then
  sfx(7)
  start_level()
 end
end

function draw_brief()
 local lv=levels[lvl]

 draw_panel(8,8,120,120)

 coprint("test "..lvl..": "..lv.title,14,10,0)
 print("",14,26)
 -- draw line
 line(14,23,114,23,13)

 -- briefing text
 print(lv.brief,14,28,7)

 -- controls available (bottom-aligned)
 local rows=0
 if lv.has_fwd then rows+=1 end
 if lv.has_rot then rows+=1 end
 if lv.has_items then rows+=1 end
 local sep_y=115-rows*10-3
 line(14,sep_y,114,sep_y,13)
 local cy=sep_y+(118-sep_y-rows*10)/2+2
 if lv.has_fwd then
  spr(0,14,cy)
  spr(1,23,cy)
  print(": thrust/brake",33,cy+1,13)
  cy+=10
 end
 if lv.has_rot then
  spr(2,14,cy)
  spr(3,23,cy)
  print(": rotate",33,cy+1,13)
  cy+=10
 end
 if lv.has_items then
  spr(4,14,cy)
  print(":cycle",23,cy+1,13)
  spr(5,52,cy)
  print(":use",61,cy+1,13)
 end

 if brief_timer>30 and flr(frame/30)%2==0 then
  coprint("press z/x",122,11,0)
 end
end

-------------------------------
-- play state
-------------------------------
function update_play()
 update_ship()
 update_bullets()
 update_obstacles()
 update_debris()
 update_fuel_pods()
 update_ammo_pods()
 update_shield_pods()
 update_grav_wells()
 update_mines()
 update_rings()
 update_particles()

 -- check success
 if ship.alive then
  -- need all debris collected before landing
  if #debris>0 and drop_zone then
   -- can't land yet
  else
   if check_landing() then
    land_timer+=1
    if land_timer>30 then
     -- success!
     score=calc_score()
     total_score+=score
     success_timer=0
     stop_all_sfx()
     state=st_success
     sfx(4)
    end
   else
    land_timer=max(0,land_timer-1)
   end
  end
 end

 -- check fail
 if not ship.alive then
  fail_timer-=1
  if fail_timer<=0 then
   stop_all_sfx()
   state=st_fail
  end
 elseif ship.fuel<=0 then
  -- check if also not moving toward goal
  local spd=sqrt(ship.dx*ship.dx+ship.dy*ship.dy)
  if spd<0.05 then
   fail_timer+=1
   if fail_timer>120 then
    stop_all_sfx()
    state=st_fail
   end
  end
 end
end

function draw_indicator(wx,wy,c,oc)
 -- convert world pos to screen pos
 local sx=wx-cam_x
 local sy=wy-cam_y
 -- skip if on screen (with margin)
 if sx>4 and sx<124 and sy>4 and sy<124 then return end
 -- direction from screen center to target
 local dx=sx-64
 local dy=sy-64
 -- find intersection with screen edge
 local ex,ey
 if abs(dx)>abs(dy) then
  -- hits left or right edge
  local s=dx>0 and 1 or -1
  ex=s>0 and 127 or 0
  ey=64+dy*(ex-64)/dx
 else
  -- hits top or bottom edge
  local s=dy>0 and 1 or -1
  ey=s>0 and 127 or 0
  ex=64+dx*(ey-64)/dy
 end
 -- clamp to screen edge
 ex=mid(0,ex,127)
 ey=mid(0,ey,127)
 -- size based on distance (bigger=farther)
 local dist=max(abs(dx),abs(dy))
 local sz=dist>150 and 3 or (dist>90 and 2 or 1)
 -- draw with pulsing outline
 local pulse=sin(frame/30)>0.2 and oc or c
 circfill(ex,ey,sz+1,pulse)
 circfill(ex,ey,sz,c)
end

function draw_play()
 -- set camera for world drawing
 camera(flr(cam_x),flr(cam_y))

 draw_grav_wells()
 draw_mines()
 draw_rings()
 draw_land()
 draw_obstacles()
 draw_debris()
 draw_fuel_pods()
 draw_ammo_pods()
 draw_shield_pods()
 draw_ship()
 draw_bullets()
 draw_particles()

 -- reset camera for HUD/UI
 camera()

 -- edge indicators for off-screen targets
 draw_indicator(land.x,land.y,11,3)
 for ob in all(obstacles) do
  draw_indicator(ob.x,ob.y,0,5)
 end
 for d in all(debris) do
  draw_indicator(d.x,d.y,6,7)
 end
 if drop_zone then
  draw_indicator(drop_zone.x,drop_zone.y,9,4)
 end
 for f in all(fuel_pods) do
  draw_indicator(f.x,f.y,11,3)
 end
 for a in all(ammo_pods) do
  draw_indicator(a.x,a.y,8,2)
 end
 for s in all(shield_pods) do
  draw_indicator(s.x,s.y,12,1)
 end
 for m in all(mines) do
  draw_indicator(m.x,m.y,8,0)
 end

 draw_hud()

 -- landing proximity indicator
 if ship.alive and land_timer>0 then
  local pct=flr(land_timer/30*100)
  cprint("LANDING "..pct.."%",58,11)
 end

 -- debris status
 if drop_zone and #debris>0 then
  print("CARGO: "..#debris.." LEFT",40,120,6)
 end

 -- disabled controls warning scroll
 if warn_scroll>=-(#warn_text*4) then
  local y=120
  for dx=-1,1 do
   for dy=-1,1 do
    if dx!=0 or dy!=0 then
     print(warn_text,warn_scroll+dx,y+dy,0)
    end
   end
  end
  print(warn_text,warn_scroll,y,8)
 end
end

-------------------------------
-- success state
-------------------------------
function update_success()
 success_timer+=1
 update_particles()
 if success_timer>60 and any_btnp() then
  sfx(7)
  if lvl>=max_lvl then
   -- game complete!
   state=st_namein
   name_chars={1,1,1}
   name_pos=1
  else
   lvl+=1
   state=st_brief
   brief_timer=0
  end
 end
end

function draw_success()
 camera(flr(cam_x),flr(cam_y))
 draw_land()
 draw_ship()
 draw_particles()
 camera()

 draw_panel(20,40,108,80)

 coprint("test passed!",46,11,0)
 print("SCORE: +"..score,38,56,7)
 print("TOTAL: "..total_score,38,64,13)

 if success_timer>60 and flr(frame/30)%2==0 then
  coprint("press z/x",72,11,0)
 end
end

-------------------------------
-- fail state
-------------------------------
function update_fail()
 update_particles()
 if btnp(4) then
  -- retry
  start_level()
 elseif btnp(5) then
  -- abort -> scores
  state=st_namein
  name_chars={1,1,1}
  name_pos=1
 end
end

function draw_fail()
 camera(flr(cam_x),flr(cam_y))
 draw_obstacles()
 draw_particles()
 camera()

 draw_panel(10,35,118,90)

 coprint("test failed!",41,8,0)
 line(16,49,112,49,13)

 if ship.fuel<=0 then
  print("yOU RAN OUT OF FUEL.\ns.c.a.m. WILL BILL YOU\nFOR THE TOW SERVICE.",16,53,7)
 else
  print("yOUR SHIP WAS DAMAGED.\nREPAIRS WILL BE DEDUCTED\nFROM YOUR SALARY.",16,53,7)
 end

 line(16,73,112,73,13)
 pal(6,3) pal(7,11)
 spr(4,30,78)
 pal()
 print("RETRY",39,79,6)
 pal(6,2) pal(7,8)
 spr(5,66,78)
 pal()
 print("ABORT",75,79,6)
end

-------------------------------
-- name input state
-------------------------------
function update_namein()
 if name_pos<=3 then
  if btnp(2) then
   name_chars[name_pos]+=1
   if name_chars[name_pos]>26 then
    name_chars[name_pos]=1
   end
  end
  if btnp(3) then
   name_chars[name_pos]-=1
   if name_chars[name_pos]<1 then
    name_chars[name_pos]=26
   end
  end
 end
 if btnp(1) or ((btnp(4) or btnp(5)) and name_pos<=3) then
  name_pos=min(4,name_pos+1)
  sfx(7)
 end
 if btnp(0) then
  name_pos=max(1,name_pos-1)
  sfx(7)
 end
 if (btnp(4) or btnp(5)) and name_pos==4 then
  local n=chr(64+name_chars[1])..chr(64+name_chars[2])..chr(64+name_chars[3])
  insert_score(n,total_score,lvl)
  sfx(7)
  state=st_scores
  scores_timer=0
 end
end

function draw_namein()
 draw_panel(15,30,113,95)

 local cc=lvl>=max_lvl and 11 or 8
 coprint("certification",36,cc,0)
 if lvl>=max_lvl then
  coprint("complete!",44,11,0)
 else
  coprint("incomplete",44,8,0)
 end

 print("TOTAL SCORE: "..total_score,28,56,7)
 print("LEVEL REACHED: "..lvl.."/"..max_lvl,24,64,7)

 print("eNTER YOUR NAME:",28,76,6)
 for i=1,3 do
  local c=13
  if i==name_pos then c=11 end
  local ch=chr(64+name_chars[i])
  print(ch,44+(i-1)*12,86,c)
  if i==name_pos and flr(frame/8)%2==0 then
   line(44+(i-1)*12,93,44+(i-1)*12+4,93,c)
  end
 end
 -- ok button
 local okc=name_pos==4 and 11 or 13
 print("ok",80,86,okc)
 if name_pos==4 and flr(frame/8)%2==0 then
  line(80,93,88,93,okc)
 end
end

-------------------------------
-- highscore state
-------------------------------
function update_scores()
 scores_timer+=1
 if scores_timer>30 and any_btnp() then
  sfx(7)
  state=st_intro
  intro_timer=0
 intro_cycle=0
 intro_page=0
 end
end

function draw_scores()
 draw_panel(10,10,118,118)

 coprint("s.c.r.a.p.",16,10,0)
 coprint("hall of fame",24,13,0)
 line(20,32,108,32,13)

 draw_hiscores(38,12)

 if #hi_names==0 then
  print("NO RECORDS YET",30,60,5)
 end

 if flr(frame/30)%2==0 then
  coprint("press z/x",110,11,0)
 end
end

__gfx__
00007000000777000007000000007000066666600666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700000777000077000000007700666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00777770000777000777777777777770667777666676676600000000000000000000000000000000000000000000000000000000000000000000000000000000
07777777000777007777777777777777666676666667766600000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700077777770777777777777770666766666667766600000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700007777700077000000007700667777666676676600000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700000777000007000000007000666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700000070000000000000000000066666600666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077707770777000000000777077707770000077707770777000000000000000007770000000000000777077707770000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000007000070000000000000070000000000000070000000000000700000700000000700000000000000700000000000000000
00000000000000070000000000000007000700000000000000070000000000000007000000000007000000070000000700000000000000070000000000000000
00000000000000070000000000000007000700000000000000070000000000000007000000000007000000070000000700000000000000070000000000000000
00000000000000070000000000000007000700000000000000070000000000000007000000000007000000070000000700000000000000070000000000000000
00000000000000700000007770777007007000000077707770070000007770000000700000000070007770007000000700000077700000007000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000
00000000000000700000000000075070000000070000000700070000000000000000700000007000000000000070000700000000000000007000000000000000
00000000000000070000000000000007000000700000000700070000000000000007000000070000000000000007000700000000000000070000000000000000
00000000000000070000750000000007000000700000000700070000000000000007000000070000000000000007000700000000000000070000000000000000
00000000000000670000000000000007000000700000000700070000000000000007000000070000000000000007000700000000000000070000000000000000
00000000000000007077707770000000700000070077700700070000000000000070000000700000007770000000700700000000007770700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000070000000000000000707000000000000000070000000700000070000070000000700000700000007000000007000000000000000000000000
00000000000000070000000000000007000700000000000000070000000700000007000700000007000000070000000700000007000000000000000000000000
00000000000000070000000000000007000700000000000000070000000700000007000700000007000000070000000700000007000000000000000000000000
00000000000000070750000000000007000700000000000000070000000700000007000700000007000000070000000700000007000000000000000000000000
00000000000000070077707770777070000070777077707770070077700700777000707000777070000000007077700070777007000000000000000000000000
00000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000dd0ddd0ddd00dd0ddd000000dd0d000ddd0ddd0dd00ddd0dd000dd00000ddd0d0d0d000ddd00dd0000000000000000000000000
000000000000000000000000d000d0d0d0d0d000d0000000d000d000d000d0d0d0d00d00d0d0d0000000d0d0d0d0d000d000d000000000000000000000000000
000000000000000000000000ddd0ddd0ddd0d000dd000000d000d000dd00ddd0d0d00d00d0d0d0000000dd00d0d0d000dd00ddd0000000000000000000000000
00000000000000000000000000d0d000d0d0d000d0000000d000d000d000d0d0d0d00d00d0d0d0d00000d0d0d0d0d000d00000d0000000000000000000000000
000000000000075000000000dd00d000d0d00dd0ddd000000dd0ddd0ddd0d0d0d0d0ddd0d0d0ddd00000d0d00dd0ddd0ddd0dd00000000000000000000000000
00000000000000000000000000000000000000050000000000000005000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000075000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000ddd0dd00dd000000ddd0ddd00dd00dd0ddd0dd00d0d0ddd0ddd00dd0000000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d0d0d00000d0d0d0d0d0d0d000d000d0d0d0d0d0d0d000d000000000000000000000000000000000000000
000000000000000000000000000000000000ddd0d0d0d0d00000ddd0dd00d0d0d000dd00d0d0d0d0dd00dd00ddd0000000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d0d0d00000d000d0d0d0d0d000d000d0d0d0d0d0d0d00000d0005000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d0ddd00000d000d0d0dd000dd0ddd0ddd00dd0d0d0ddd0dd00000000000000000000000000000000006000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000eee0000000000000eee0000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000e0e0eee0e0e00000e000ee00eee0eee0eee00ee0ee00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000eee00e00e0e00000ee00e0e00e050e000e00e0e0e0e0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000e00e00eee00000e000e0e00e000e000e00e0e0e0e0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000e00e00e0e00000eee0ee00eee00e00eee0ee00e0e0000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000750000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000007500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000075000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000075000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000600000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000500
00000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000005000000500000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000075000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000050000000005000000000000000000000000000000000000000000000000000000000000
00000000000000000000000007000000000700000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077000000000770000666006606660666066606660066066000000000006606660666066606660666066000660000000000000000
00000000000000000000000777777707777777000606060600600606006000600606060600600000060000600600060006060060060606000000000000000000
00000000000000000000007777777707777777700660060600600666006000600606060600000000066600600660066006600060060606000000000000000000
00000000000000000000000777777707777777000606060600600606006000600606060600600000000600600600060006060060060606060000000000000000
00000000000000000000000077000000000770000606066000600606006006660660060600000000066000600666066606060666060606660000000000000000
00000000000000000000000007000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000750000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000075000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000000000075000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000bbb0bb000bb0bbb00bb0bbb000000bb00bb0bb00bbb0bbb00bb0b0000bb00000000000000000000000000000000000
0000000000000000000000000000000000b000b0b0b000b0b0b000b0000000b000b0b0b0b00b00b0b0b0b0b000b0000000000000000000000000000000000000
0000000000000000000000000000000000bb00b0b0b000bbb0b000bb000000b000b0b0b0b00b00bb00b0b0b000bbb00000000000000000000000000000000000
0000000000000000000000000000000000b000b0b0b0b0b0b0b0b0b0000000b000b0b0b0b00b00b0b0b0b0b00000b00000000000000000000000000000000000
0000000000000000000000000000000000bbb0b0b0bbb0b0b0bbb0bbb000000bb0bb00b0b00b00b0b0bb00bbb0bb000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007500000000000000000006000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000750000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000750000000000000000000000000000000000000000000000
00000000000000000000000000000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000005500000000000000000000005500000000000000000000000000000
55505500000055505050055050005050055055505050555050005050000055500550000050000550055005505550000050005000555005505500555055000550
55005050000055007500500050005050500005005050550050005550000005005050000055505050505050005500000050005000550050505050550050505000
50005050000050050500500050005050005005005550500050000050000005005050000000505550555050005000000050005000500055505050500055000050
05505500000005505050055005500550550055500500055005505500000005005500000055005000505005500550000005500550055050505050055050505500
00000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000800001805018050180500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000000000
000400001c0501f05024050290502d050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000000000
000200000c7500c7500a7500875006750047500275001750007500075000750007500075000050000500005000050000500005000050000500005000050000500005000050000500005000050000000000000000
000300001865018650186001860018600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000000000000
000400002405024050210501e0501b050180501505012050100500e0500c0500a0500805006050040500205000050000500005000050000500005000050000500005000050000500005000050000000000000000
000300000075003750067500975006750037500075000750007500075000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000000000000
000200001035010350103501035010350103500e3500e3500e3500e35000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001805018050240500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400041864018640186401864018640186401864018640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400042063020630206302063020630206302063020630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
