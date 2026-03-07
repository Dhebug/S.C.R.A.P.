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
st_intro=0
st_brief=1
st_play=2
st_success=3
st_fail=4
st_scores=5
st_namein=6

state=st_intro
lvl=1
max_lvl=4
score=0
total_score=0
frame=0

-- ui feedback
warn_scroll=-1
warn_text=""

-- physics
friction=0.995
max_spd=2

-- controls
reverse_rot=true -- true=left steers left (ship rotates cw), false=direct

-------------------------------
-- ship
-------------------------------
ship={}

function init_ship(x,y,ang)
 ship={
  x=x,y=y,
  dx=0,dy=0,
  ang=ang or 0,
  fuel=100,
  thrust_f=0, -- forward visual
  thrust_b=0, -- brake visual
  thrust_l=0, -- left visual
  thrust_r=0, -- right visual
  item=1, -- selected item (1=laser,2=cable)
  ammo=10,
  cable_out=false,
  cable_tgt=nil,
  alive=true,
  snd_main=false,
  snd_lat=false
 }
end

function update_ship()
 if not ship.alive then return end

 local lv=levels[lvl]
 local pwr=0.06
 local rpwr=0.02
 local bpwr=0.03

 -- reset thrust visuals
 ship.thrust_f=0
 ship.thrust_b=0
 ship.thrust_l=0
 ship.thrust_r=0

 -- forward thrust (up)
 if btn(2) and lv.has_fwd and ship.fuel>0 then
  ship.dx+=cos(ship.ang)*pwr
  ship.dy+=sin(ship.ang)*pwr
  ship.fuel-=0.15
  ship.thrust_f=1
 end

 -- brake thrust (down)
 if btn(3) and lv.has_fwd and ship.fuel>0 then
  ship.dx-=cos(ship.ang)*bpwr
  ship.dy-=sin(ship.ang)*bpwr
  ship.fuel-=0.1
  ship.thrust_b=1
 end

 -- rotate
 local rdir=reverse_rot and 1 or -1
 if btn(0) and lv.has_rot and ship.fuel>0 then
  ship.ang+=rpwr*rdir
  ship.fuel-=0.05
  if reverse_rot then ship.thrust_r=1 else ship.thrust_l=1 end
 end
 if btn(1) and lv.has_rot and ship.fuel>0 then
  ship.ang-=rpwr*rdir
  ship.fuel-=0.05
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
  local dist=sqrt(cdx*cdx+cdy*cdy)
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

 -- wrap or clamp to play area
 ship.fuel=max(0,ship.fuel)

 -- check bounds - fail if too far
 if ship.x<-20 or ship.x>148
  or ship.y<-20 or ship.y>148 then
  ship_die()
 end
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

 line(nx,ny,lx,ly,7)
 line(nx,ny,rx,ry,7)
 line(lx,ly,rx,ry,12)

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
    if ddx*ddx+ddy*ddy<ob.r*ob.r then
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
 local best,bd=nil,30
 for d in all(debris) do
  local ddx=ship.x-d.x
  local ddy=ship.y-d.y
  local dist=sqrt(ddx*ddx+ddy*ddy)
  if dist<bd then
   best=d
   bd=dist
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

function update_obstacles()
 for ob in all(obstacles) do
  ob.x+=ob.dx or 0
  ob.y+=ob.dy or 0
  -- check ship collision
  if ship.alive then
   local ddx=ship.x-ob.x
   local ddy=ship.y-ob.y
   if ddx*ddx+ddy*ddy<(ob.r+3)*(ob.r+3) then
    ship_die()
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
   if ddx*ddx+ddy*ddy<drop_zone.r*drop_zone.r then
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

function init_land(x,y,r)
 land={x=x,y=y,r=r or 8}
end

function check_landing()
 if not ship.alive then return false end
 local ddx=ship.x-land.x
 local ddy=ship.y-land.y
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
   c=spd>0.3 and 7 or (spd>0.2 and 6 or 5)
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
 local dir=star_dir==0 and -1 or 1
 for s in all(stars) do
  pset(s.x,s.y,s.c)
  if s.spd>0.3 then
   pset(s.x-dir,s.y,5)
  end
 end
end

-------------------------------
-- levels
-------------------------------
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
   init_ship(20,64,0)
   init_land(108,64)
   obstacles={}
   debris={}
   bullets={}
   drop_zone=nil
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
   init_ship(30,90,0)
   init_land(100,30)
   obstacles={}
   debris={}
   bullets={}
   drop_zone=nil
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
   init_ship(20,64,0)
   init_land(108,64)
   obstacles={
    {x=64,y=64,r=8,hp=3,dx=0,dy=0}
   }
   debris={}
   bullets={}
   drop_zone=nil
   ship.ammo=10
   ship.item=1
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
   init_ship(20,100,0)
   init_land(108,20)
   obstacles={
    {x=80,y=60,r=6,hp=2,dx=0,dy=0}
   }
   debris={
    {x=50,y=40,dx=0,dy=0,collected=false}
   }
   drop_zone={x=108,y=100,r=12}
   bullets={}
   ship.ammo=10
   ship.item=1
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

function coprint(t,y,c,oc)
 local x=64-#t*2
 for dx=-1,1 do
  for dy=-1,1 do
   if dx!=0 or dy!=0 then
    print(t,x+dx,y+dy,oc)
   end
  end
 end
 print(t,x,y,c)
end

-------------------------------
-- chrome panel
-------------------------------
function draw_panel(x0,y0,x1,y1)
 -- top-left outer: white
 line(x0,y0,x1,y0,7)
 line(x0,y0,x0,y1,7)
 -- bottom-right outer: light blue
 line(x0+1,y1,x1,y1,12)
 line(x1,y0+1,x1,y1,12)
 -- top-left middle: light blue
 line(x0+1,y0+1,x1-1,y0+1,12)
 line(x0+1,y0+1,x0+1,y1-1,12)
 -- bottom-right middle: white
 line(x0+1,y1-1,x1-1,y1-1,7)
 line(x1-1,y0+1,x1-1,y1-1,7)
 -- inner: black on top-left
 line(x0+2,y0+2,x1-2,y0+2,0)
 line(x0+2,y0+2,x0+2,y1-2,0)
 -- fill interior
 rectfill(x0+3,y0+3,x1-2,y1-2,1)
end

-------------------------------
-- hud
-------------------------------
function draw_hud()
 -- fuel bar
 local fw=flr(ship.fuel*0.4)
 local fc=11
 if ship.fuel<30 then fc=8 end
 if ship.fuel<15 then fc=flr(frame/4)%2==0 and 8 or 0 end
 rectfill(2,2,2+40,5,0)
 rectfill(2,2,2+fw,5,fc)
 rect(2,2,2+40,5,6)
 print("fuel",2,8,6)

 -- speed indicator
 local spd=sqrt(ship.dx*ship.dx+ship.dy*ship.dy)
 local sc=11
 if spd>1.5 then sc=8 end
 print("spd:"..flr(spd*100)/100,80,2,sc)

 -- item display
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
  print("["..iname.."]",80,8,ic)
  if ship.item==1 then
   print("ammo:"..ship.ammo,80,14,7)
  end
 end

 -- level indicator
 print("test "..lvl.."/"..max_lvl,46,2,13)
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
brief_timer=0
success_timer=0
fail_timer=0
land_timer=0

-- highscore
hi_names={}
hi_scores={}
hi_levels={}
name_chars={1,1,1} -- a=1
name_pos=1

function load_scores()
 hi_names={}
 hi_scores={}
 hi_levels={}
 for i=0,4 do
  local c1=dget(i*5)
  local c2=dget(i*5+1)
  local c3=dget(i*5+2)
  local sc=dget(i*5+3)
  local lv=dget(i*5+4)
  if sc>0 then
   add(hi_names,chr(64+c1)..chr(64+c2)..chr(64+c3))
   add(hi_scores,sc)
   add(hi_levels,lv)
  end
 end
end

function save_scores()
 for i=1,min(#hi_names,5) do
  local n=hi_names[i]
  dset((i-1)*5,ord(n,1)-64)
  dset((i-1)*5+1,ord(n,2)-64)
  dset((i-1)*5+2,ord(n,3)-64)
  dset((i-1)*5+3,hi_scores[i])
  dset((i-1)*5+4,hi_levels[i])
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
 for i=1,pos-1 do
  add(nn,hi_names[i])
  add(ns,hi_scores[i])
  add(nl,hi_levels[i])
 end
 add(nn,name)
 add(ns,sc)
 add(nl,lv)
 for i=pos,#hi_names do
  add(nn,hi_names[i])
  add(ns,hi_scores[i])
  add(nl,hi_levels[i])
 end
 hi_names=nn
 hi_scores=ns
 hi_levels=nl
 -- cap at 5
 while #hi_names>5 do
  hi_names[#hi_names]=nil
  hi_scores[#hi_scores]=nil
  hi_levels[#hi_levels]=nil
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
 state=st_play
end

function calc_score()
 -- score based on fuel remaining and level
 return flr(ship.fuel*10+lvl*50)
end

-------------------------------
-- main pico-8 callbacks
-------------------------------
function _init()
 cartdata("scrap_scam_2126")
 init_stars()
 load_scores()
 reverse_rot=dget(30)!=1 -- default true unless explicitly set to 1 (direct)
 star_dir=reverse_rot and 0 or 1
 state=st_intro
 intro_timer=0
 --cheat: uncomment to skip to a level
 --state=st_brief lvl=3
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
 scroll_pos+=0.8
 if scroll_pos>30000 then scroll_pos=0 end
 update_stars()
 -- toggle rotation mode with left/right
 if intro_timer>60 and (btnp(0) or btnp(1)) then
  reverse_rot=not reverse_rot
  star_dir=reverse_rot and 0 or 1
  dset(30,reverse_rot and 0 or 1)
  sfx(3)
 end
 -- start game with up/down/o/x
 if intro_timer>60 and (btnp(2) or btnp(3) or btnp(4) or btnp(5)) then
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
 print("/ __|/ __| _ \\  /_\\ | _ \\",c)
 print("\\__ \\ (_||   / / _ \\|  _/",c)
 print("|___/\\___|_|_\\/_/ \\_\\_|",c)

 -- cycle between title info and highscores
 local show_scores=intro_timer>200 and flr(frame/300)%2==1 and #hi_names>0

 if show_scores then
  -- show highscores
  print("NAME  SCORE  LEVEL",24,38,6)
  line(20,45,108,45,5)
  for i=1,min(#hi_names,5) do
   local y=48+(i-1)*10
   local c=7
   if i==1 then c=10 end
   print(hi_names[i],28,y,c)
   print(tostr(hi_scores[i]),56,y,c)
   print(tostr(hi_levels[i]).."/"..max_lvl,92,y,c)
  end
 else
  if intro_timer>80 then
   print("space cleaning rules",24,36,13)
   print("and procedures",36,44,13)
   if intro_timer>160 then
     print("9TH eDITION",42,51,14)
    end
  end
 end

 if intro_timer>60 then
  local mode=reverse_rot and "steering" or "direct"
  spr(2,22,73)
  spr(3,31,73)
  print("rotation: "..mode,41,74,6)
  if flr(frame/15)%2==0 then
   coprint("engage controls",98,11,0)
  end
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

 if brief_timer>30 and flr(frame/15)%2==0 then
  coprint("engage controls",122,11,0)
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
 update_particles()

 -- check success
 if ship.alive then
  -- for level 4, need all debris collected first
  if lvl==4 and #debris>0 then
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

function draw_play()
 draw_land()
 draw_obstacles()
 draw_debris()
 draw_ship()
 draw_bullets()
 draw_particles()
 draw_hud()

 -- landing proximity indicator
 if ship.alive and land_timer>0 then
  local pct=flr(land_timer/30*100)
  print("landing "..pct.."%",42,58,11)
 end

 -- level 4: debris status
 if lvl==4 and #debris>0 then
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
 draw_land()
 draw_ship()
 draw_particles()

 draw_panel(20,40,108,80)

 coprint("test passed!",46,11,0)
 print("SCORE: +"..score,38,56,7)
 print("TOTAL: "..total_score,38,64,13)

 if success_timer>60 and flr(frame/15)%2==0 then
  coprint("engage controls",72,11,0)
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
 draw_obstacles()
 draw_particles()

 draw_panel(20,35,108,90)

 coprint("test failed!",41,8,0)

 if ship.fuel<=0 then
  cprint("OUT OF FUEL",52,7)
 else
  cprint("SHIP DESTROYED",52,7)
 end

 spr(4,44,67)
 print(": RETRY",53,68,11)
 spr(5,44,77)
 print(": ABORT",53,78,8)
end

-------------------------------
-- name input state
-------------------------------
function update_namein()
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
 if btnp(1) then
  name_pos=min(3,name_pos+1)
 end
 if btnp(0) then
  name_pos=max(1,name_pos-1)
 end
 if btnp(4) or btnp(5) then
  local n=chr(64+name_chars[1])..chr(64+name_chars[2])..chr(64+name_chars[3])
  insert_score(n,total_score,lvl)
  state=st_scores
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
  print(ch,48+(i-1)*12,86,c)
  if i==name_pos and flr(frame/8)%2==0 then
   line(48+(i-1)*12,93,48+(i-1)*12+4,93,c)
  end
 end
end

-------------------------------
-- highscore state
-------------------------------
function update_scores()
 if any_btnp() then
  sfx(7)
  state=st_intro
  intro_timer=0
 end
end

function draw_scores()
 draw_panel(10,10,118,118)

 coprint("s.c.r.a.p.",16,10,0)
 coprint("hall of fame",24,13,0)
 line(20,32,108,32,13)

 print("NAME  SCORE  LEVEL",24,38,6)
 line(20,45,108,45,5)

 for i=1,min(#hi_names,5) do
  local y=48+(i-1)*12
  local c=7
  if i==1 then c=10 end
  print(hi_names[i],28,y,c)
  print(tostr(hi_scores[i]),56,y,c)
  print(tostr(hi_levels[i]).."/"..max_lvl,92,y,c)
 end

 if #hi_names==0 then
  print("NO RECORDS YET",30,60,5)
 end

 if flr(frame/15)%2==0 then
  coprint("engage controls",110,11,0)
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000007500000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000005000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007500000000
00000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077707770777000000000777077707770000077707770777000000000000000007770000000000000777077707770000000000000000000
00000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000007000000000000007000070000000000000070000000000000070000000000000700000700000000700000000000000700000000000000000
00000000000000070000000000000007000700000000000000070000000000000007000000000007000000070000000700000000000000070000000000000000
00000000000000070000000000000007000700000750000000070000000000000007000060000007000000070000000700000000000000070000000000000075
00000000000000070000000000000007000700000000000000070000000000000007000000000007000000070000000700000000000000070000000000000000
00000000000000700000007770777007007000000077707770070000007770000000700000000070007770007000000700000077700000007000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000700000000000000070000000070000000700070000000000000000700000007000000000000070000700000000000000007000000000000000
00000000000000070000000000000007000000700000000700070000000000000007000000070000000000000007000700000000000000070000000000000000
00000000000000070000000000000007000000700000000700070000000000000007000000070000000000000007000700000000000000070000000000000000
00000000000000070000000007500007000000700000000700070000000000000007000000070000000000000007000700000000000000070000000000000000
00000000000000007077707770000000700000070077700700070000000000000070000000700000007770000000700700000000007770700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000070000000000000000707000000000000000070000000700000070000070000000700000700000007000000007000000000000000000000000
00000000000000070000000000000007000700000000000000070000000700000007000700000007000000070000000700000007000000000000000000000000
00000000000000070000000000000007000700000000000000070000000700000007000700000007000000070000000700000007000000000000000000000050
00000000000000070000000000000007000700000000000000070000000700000007000700000007000000070000000700000007000000000000000000000000
00000000000000070077707770777070000070777077707770070077700700777000707000777070000000007077700070777007000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000
00000000000000000000007500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000dd0ddd0ddd00dd0ddd000000dd0d000ddd0ddd0dd00ddd0dd000dd00000ddd0d0d0d000ddd00dd0000000000000000000000000
000000000000000000000000d000d0d0d0d0d000d0000000d000d000d005d7d0d0d00d00d0d0d0000000d0d0d0d0d000d000d000000000000000000000000000
000000000000000000000000ddd0ddd0ddd0d000dd000000d000d000dd00ddd0d7d00d00d0d0d0000000dd00d0d0d000dd00ddd0000000000000000000000000
00000000000000000000000000d0d000d0d0d000d0000000d000d000d000d0d0d0d00d00d0d0d0d00000d0d0d0d0d000d00000d0000000000000000000000000
000000000000000000000000dd00d000d0d00dd0ddd000000dd0ddd0ddd0d0d0d0d0ddd0d0d0ddd00000d0d00dd0ddd0ddd0dd07500000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000ddd0dd00dd000000ddd0ddd00dd00dd0ddd0dd00d0d0ddd0ddd00dd0000000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d0d0d00000d0d0d0d0d0d0d000d000d0d0d0d0d0d0d000d000000000000000000000000000000000000000
000000000000000000000000000000000000ddd0d0d0d0d00000ddd0dd00d0d0d000dd00d0d0d0d0dd00dd00ddd0000000000000000000000000000000000000
000000000000000000000000000000000000d0d0d0d0d0d00000d000d0d0d0d0d000d000d0d0d0d0d0d0d00000d0000000000000000000000000000000000000
000000000000000000000000000000075000d0d0d0d0ddd00000d000d0d0dd000dd0ddd0ddd00dd0d0d0ddd0dd00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000075000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000007500000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000060600000006660066066606660666066600660660000000000066066606660666066606660660006600000000000000000000000
00000000000000000000000600060000006060606006006060060006006060606006000000600006006000600060600600606060000000000000000000000000
00000000000000000000006000006000006600606006006660060006006060606000000000666006006600660066000600606060000000000000000006000000
00000000000000000000000600060000006060606006006060060006006060606006000000006006006000600060600600606060600000000000000000000000
00000000000000000000750060600000006060660006006060060066606600606000000000660006056660666060606660606066600000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000750000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000007500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000075000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007500000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000007500000000000000000000000005000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000075000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000050
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000060000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000750000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000750000000000000000000000000000000000000
00000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000050005500500000055505500555050000000055000500000000000000000055000000000000000000000000000000000555000000000000
00000000000000000500050000050000000500500005050000000500005500550055055500000500050005550055055005550550005500000505055005050055
00000000000000000500050000050000055500500555055500000555050505050500055000000500050005500505050500500505050000000555050505050505
00000000000000000500050000050000050000500500050500000005055505550500050000000500050005000555050500500505050500000505057505550555
00000000000000000050005500500000055505550555055500000550050005050055005500000055005500550505050505550505055500000505055000500505
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000800001805018050180500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000000000
000400001c0501f05024050290502d050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500000000000
000200000c7500c7500a7500875006750047500275001750007500075000750007500075000050000500005000050000500005000050000500005000050000500005000050000500005000050000000000000000
000300001865018650186001860018600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000000000000
000400002405024050210501e0501b050180501505012050100500e0500c0500a0500805006050040500205000050000500005000050000500005000050000500005000050000500005000050000000000000000
000300000075003750067500975006750037500075000750007500075000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000000000000000
000200001035010350103501035010350103500e3500e3500e3500e3500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800001805018050240500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000418640186401864018640186401864018640186400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000420630206302063020630206302063020630206300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
