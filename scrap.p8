pico-8 cartridge // http://www.pico-8.com
version 42
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
  alive=true
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
 sfx(2)
end

function update_bullets()
 for b in all(bullets) do
  b.x+=b.dx
  b.y+=b.dy
  b.life-=1
  if b.life<=0 then
   del(bullets,b)
  else
   -- check obstacle collision
   for ob in all(obstacles) do
    local ddx=b.x-ob.x
    local ddy=b.y-ob.y
    if ddx*ddx+ddy*ddy<ob.r*ob.r then
     ob.hp-=1
     del(bullets,b)
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
  brief="navigate from point a\nto the landing zone in\na straight line.\n\nsimple, right?\n\nscam believes in you.\nmostly.",
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
  brief="the landing zone isn't\nalways in front of you.\n\ntime to learn how to\nturn.\n\ntry not to get dizzy.",
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
  brief="sometimes the trash is\nin the way.\n\nthat's why we gave you\na laser.\n\nplease don't point it\nat coworkers.",
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
  brief="not everything is trash.\nsome things are valuable\ntrash.\n\nuse the tow cable to\nhaul debris to the\ncollection zone.\n\nthen land safely.",
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

 if intro_timer>80 then
  print("space cleaning rules",24,36,13)
  print("and procedures",36,44,13)
  if intro_timer>160 then
    print("9TH eDITION",42,51,14)
   end
 end

 if intro_timer>60 then
  local mode=reverse_rot and "steering" or "direct"
  print("<> rotation: "..mode,22,74,6)
  if flr(frame/15)%2==0 then
   print("engage controls",36,98,11)
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
  start_level()
 end
end

function draw_brief()
 local lv=levels[lvl]

 rect(8,8,120,120,13)
 rectfill(9,9,119,119,1)

 print("test "..lvl..": "..lv.title,14,14,11)
 print("",14,26)
 -- draw line
 line(14,23,114,23,13)

 -- briefing text
 print(lv.brief,14,28,7)

 -- controls available
 local cy=80
 print("controls:",14,cy,6)
 if lv.has_fwd then
  print("^ v : thrust/brake",14,cy+8,13)
 end
 if lv.has_rot then
  print("< > : rotate",14,cy+16,13)
 end
 if lv.has_items then
  print("o:cycle item x:use",14,cy+24,13)
 end

 if brief_timer>30 and flr(frame/15)%2==0 then
  print("engage controls",18,112,11)
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
   state=st_fail
  end
 elseif ship.fuel<=0 then
  -- check if also not moving toward goal
  local spd=sqrt(ship.dx*ship.dx+ship.dy*ship.dy)
  if spd<0.05 then
   fail_timer+=1
   if fail_timer>120 then
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
  print("cargo: "..#debris.." left",40,120,6)
 end
end

-------------------------------
-- success state
-------------------------------
function update_success()
 success_timer+=1
 update_particles()
 if success_timer>60 and any_btnp() then
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

 rectfill(20,40,108,80,1)
 rect(20,40,108,80,11)

 print("test passed!",36,46,11)
 print("score: +"..score,38,56,7)
 print("total: "..total_score,38,64,13)

 if success_timer>60 and flr(frame/15)%2==0 then
  print("engage controls",40,72,6)
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

 rectfill(20,35,108,90,1)
 rect(20,35,108,90,8)

 print("test failed!",36,41,8)

 if ship.fuel<=0 then
  print("out of fuel",38,52,7)
 else
  print("ship destroyed",32,52,7)
 end

 print("o: retry",44,68,11)
 print("x: abort",44,78,8)
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
 rectfill(15,30,113,95,1)
 rect(15,30,113,95,13)

 print("certification",34,36,lvl>=max_lvl and 11 or 8)
 if lvl>=max_lvl then
  print("complete!",42,44,11)
 else
  print("incomplete",40,44,8)
 end

 print("total score: "..total_score,28,56,7)
 print("level reached: "..lvl.."/"..max_lvl,24,64,7)

 print("enter your name:",28,76,6)
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
  state=st_intro
  intro_timer=0
 end
end

function draw_scores()
 rect(10,10,118,118,13)
 rectfill(11,11,117,117,1)

 print("s.c.r.a.p.",38,16,11)
 print("hall of fame",36,24,13)
 line(20,32,108,32,13)

 print("name  score  level",24,38,6)
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
  print("no records yet",30,60,5)
 end

 if flr(frame/15)%2==0 then
  print("engage controls",32,110,6)
 end
end

__gfx__

__gff__

__map__

__sfx__
0008000018050180501805000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000400001c0501f05024050290502d0500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000200000c7500c7500a7500875006750047500275001750007500075000750007500075000050000500005000050000500005000050000500005000050000500005000050000500005000050000
000300001865018650186001860018600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
000400002405024050210501e0501b050180501505012050100500e0500c0500a050080500605004050020500005000050000500005000050000500005000050000500005000050000500005000
000300000075003750067500975006750037500075000750007500075000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000

__music__

