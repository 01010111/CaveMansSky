package;

#if mobile
import cpp.Void;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;
import zerolib.ZMath;

class PlayState extends FlxState
{
	
	public static var i:PlayState;
	
	public var caveman:CaveMan;
	public var nimbus:Nimbus;
	public var reticle:ReticleStuff;
	
	public var state:Int = 0;
	
	public var fg_poofs:Poofs;
	public var bg_poofs:Poofs;
	public var water_poofs:Poofs;
	
	public var background:BackGround;
	public var tension:FlxSprite;
	public var ui:UILayer;
	public var mines:Mines;
	public var explosion_layer:FlxGroup;
	public var ufos:FlxGroup;
	
	public var ufos_on_screen:Int = 0;
	public var max_ufos:Int = 2;
	
	var dt:FlxText;
	
	override public function create():Void
	{
		i = this;
		
		FlxG.mouse.visible = false;
		bgColor = 0xff5fcde4;
		ui = new UILayer();
		explosion_layer = new FlxGroup();
		
		background = new BackGround();
		add(background);
		
		bg_poofs = new Poofs(20, [0xffcbdbfc, 0xff9badb7]);
		add(bg_poofs);
		
		ufos = new FlxGroup();
		add(ufos);
		
		mines = new Mines();
		add(mines);
		
		reticle = new ReticleStuff();
		add(reticle);
		
		caveman = new CaveMan();
		nimbus = new Nimbus();
		
		add(caveman);
		add(nimbus);
		
		fg_poofs = new Poofs(20, [0xffffffff]);
		add(fg_poofs);
		
		water_poofs = new Poofs(32, [0xff639bff, 0xff5b6ee1]);
		add(water_poofs);
		
		add(explosion_layer);
		add(ui);
		
		tension = new FlxSprite(0, 0, "assets/images/tension.png");
		tension.alpha = 0.25;
		FlxTween.tween(tension.scale, {x:1.25, y:1.25}, 0.5, {type:FlxTween.LOOPING});
		add(tension);
		
		cloud_start();
		
		dt = new FlxText(10, 10);
		add(dt);
		
		//new FlxTimer().start(4, add_ufo, 0);
	}
	
	function add_ufo(t:FlxTimer):Void
	{
		if (ufos_on_screen < max_ufos)
			ufos.add(new Ufo());
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		switch(state)
		{
			case 0: // CLOUD HYPE
				cloud_update();
			case 1: // CLOUD AIMM
				cloud_aim_update();
			case 2: // CANNONBALL
				cannonball_update();
			case 3: // CANNON AIM
		}
		
		FlxG.timeScale = caveman.in_danger && caveman.exists ? 0.5 : 1;
		tension.visible = caveman.in_danger && caveman.exists;
		
		if (!caveman.in_danger)
			FlxG.overlap(mines, caveman, hit_mine);
		
		#if debug
		dt.text = "" + state;
		if (FlxG.keys.justPressed.R)
			FlxG.resetState();
		#end
	}
	
	function hit_mine(_m:Mine, _c:CaveMan):Void
	{
		_m.explode();
		_c.kill();
	}
	
	function cloud_start():Void
	{
		reticle.activate(true);
		caveman.set_on_nimbus();
		state = 0;
	}
	
	function cloud_update():Void
	{
		if (FlxG.mouse.justPressed)
			cloud_aim_start();
	}
	
	function cloud_aim_start():Void
	{
		nimbus.controlling = false;
		reticle.start();
		state = 1;
	}
	
	function cloud_aim_update():Void
	{
		if (FlxG.mouse.justReleased)
			cannonball_start();
	}
	
	function cannonball_start():Void
	{
		caveman.cannonball(reticle.get_current_angle());
		reticle.stop();
		reticle.activate(false);
		state = 2;
		
		for (i in 0...6)
		{
			bg_poofs.fire(
				nimbus.getMidpoint(), 
				ZMath.velocityFromAngle(360 + 360 / 7 * i + ZMath.randomRange( -10, 10), ZMath.randomRange(100, 200)),
				ZMath.randomRangeInt(2, 5)
			);
			fg_poofs.fire(
				nimbus.getMidpoint(), 
				ZMath.velocityFromAngle(360 + 360 / 7 * i + ZMath.randomRange( -10, 10), ZMath.randomRange(100, 200)),
				ZMath.randomRangeInt(3, 7)
			);
		}
	}
	
	function cannonball_update():Void
	{
		FlxG.overlap(ufos, caveman, hit_ufo);
		
		if (FlxG.collide(caveman, nimbus))
		{
			cloud_start();
			for (i in 0...6)
			{
				bg_poofs.fire(
					nimbus.getMidpoint(), 
					ZMath.velocityFromAngle(360 + 360 / 7 * i + ZMath.randomRange( -10, 10), ZMath.randomRange(100, 200)),
					ZMath.randomRangeInt(2, 5)
				);
				fg_poofs.fire(
					nimbus.getMidpoint(), 
					ZMath.velocityFromAngle(360 + 360 / 7 * i + ZMath.randomRange( -10, 10), ZMath.randomRange(100, 200)),
					ZMath.randomRangeInt(3, 7)
				);
			}
		}
	}
	
	function hit_ufo(_u:Ufo, _c:CaveMan):Void
	{
		_u.kill();
	}
	
}

class WindowBouncer extends FlxSprite
{
	
	var top_bound:Float = -9999;
	
	public function new(_x:Float, _y:Float)
	{
		super(_x, _y);
		PlayState.i.background.add_shadow(this);
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (x > FlxG.width - width)
			velocity.x = -Math.abs(velocity.x);
		if (x < 0)
			velocity.x = Math.abs(velocity.x);
		if (y > FlxG.height - height - 20)
			hit_bottom();
		if (y < top_bound)
			velocity.y = Math.abs(velocity.y);
		
		super.update(elapsed);
	}
	
	function hit_bottom():Void
	{
		velocity.y = -ZMath.clamp(maxVelocity.y, 50, 500);
		for (i in 0...16)
		{
			PlayState.i.water_poofs.fire(getMidpoint(), ZMath.velocityFromAngle(180 + 100 / 8 * i + ZMath.randomRange(-15, 15), ZMath.randomRange(150, 250)), ZMath.randomRangeInt(3, 6));
			PlayState.i.fg_poofs.fire(getMidpoint(), ZMath.velocityFromAngle(180 + 100 / 8 * i + ZMath.randomRange(-15, 15), ZMath.randomRange(150, 250)), ZMath.randomRangeInt(1, 3));
		}
	}
	
}

class CaveMan extends WindowBouncer
{
	
	public var on_nimbus:Bool;
	public var in_danger:Bool = false;
	
	public function new()
	{
		super(68, FlxG.height * 0.5 - 16);
		loadGraphic("assets/images/caveman.png", true, 16, 16);
		animation.add("idle", [0, 1, 2, 3, 4, 5], 12);
		animation.add("fall", [6, 7, 8, 9], 20);
		animation.add("cannonball", [17, 16, 15, 14, 13, 12, 11, 10]);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (on_nimbus)
			setPosition(PlayState.i.nimbus.x + 4, PlayState.i.nimbus.y - 16);
		acceleration.y = on_nimbus ? 0 : 300;
		//allowCollisions = on_nimbus ? 0x0000 : 0x1111;
		if (in_danger)
			danger_mode();
	}
	
	function danger_mode():Void
	{
		scale.y = FlxMath.signOf(velocity.y);
	}
	
	override function hit_bottom():Void 
	{
		if (in_danger)
		{
			in_danger = false;
			for (i in 0...32)
				PlayState.i.water_poofs.fire(getMidpoint(), ZMath.velocityFromAngle(ZMath.randomRange(0, 360), ZMath.randomRange(100, 220)), ZMath.randomRangeInt(3, 7));
			for (i in 0...16)
				PlayState.i.fg_poofs.fire(FlxPoint.get(getMidpoint().x + ZMath.randomRange(-8, 8), getMidpoint().y), ZMath.velocityFromAngle(270, ZMath.randomRange(100, 450)), ZMath.randomRangeInt(3, 6));
			kill();
		}
		take_hit();
	}
	
	public function take_hit():Void
	{
		if (!in_danger)
		{
			y = FlxG.height - 21 - height;
			for (i in 0...32)
				PlayState.i.water_poofs.fire(getMidpoint(), ZMath.velocityFromAngle(ZMath.randomRange(0, 360), ZMath.randomRange(100, 220)), ZMath.randomRangeInt(3, 7));
			in_danger = true;
			velocity.set(velocity.x * 0.3, -300);
			animation.play("fall");
		}
	}
	
	public function set_on_nimbus():Void
	{
		scale.y = 1;
		last.set(PlayState.i.nimbus.x + 4, PlayState.i.nimbus.y - 16);
		setPosition(PlayState.i.nimbus.x + 4, PlayState.i.nimbus.y - 16);
		on_nimbus = true;
		if (in_danger)
			FlxG.camera.flash(0xffffffff, 0.2);
		in_danger = false;
		animation.play("idle");
	}
	
	public function cannonball(_stuff:AnglePower):Void
	{
		on_nimbus = false;
		var _v = ZMath.velocityFromAngle(_stuff.angle, ZMath.map(_stuff.power, 0, 1, 100, 240));
		velocity.set(_v.x, _v.y);
		animation.play("cannonball");
	}
	
	override public function kill():Void 
	{
		if (exists)
		{
			new FlxTimer().start(2).onComplete = function(t:FlxTimer):Void
			{
				PlayState.i.openSubState(new GameOver());
			}
			super.kill();
		}
	}
	
}

class Nimbus extends WindowBouncer
{
	
	public var controlling:Bool = true;
	
	public function new()
	{
		super(64, FlxG.height * 0.5);
		loadGraphic("assets/images/nimbus.png", true, 24, 16);
		animation.add("play", [0, 1, 2, 3], 20);
		animation.play("play");
		setSize(24, 8);
		offset.set(0, 3);
		maxVelocity.set(140, 140);
		drag.set(100, 100);
		PlayState.i.add(new NimbusTail());
		top_bound = 0;
		
		allowCollisions = 0x0100;
	}
	
	override public function update(elapsed:Float):Void 
	{
		controls();
		wiggle();
		super.update(elapsed);
	}
	
	var accel_amt:Float = 800;
	
	function controls():Void
	{
		acceleration.set();
		if (FlxG.keys.pressed.W)
			acceleration.y -= accel_amt;
		if (FlxG.keys.pressed.S)
			acceleration.y += accel_amt;
		if (FlxG.keys.pressed.A)
			acceleration.x -= accel_amt;
		if (FlxG.keys.pressed.D)
			acceleration.x += accel_amt;
	}
	
	var wiggle_amt:Float = 4;
	
	function wiggle():Void
	{
		velocity.x += ZMath.randomRange( -wiggle_amt, wiggle_amt);
		velocity.y += ZMath.randomRange( -wiggle_amt, wiggle_amt);
	}
	
}

class NimbusTail extends FlxTypedGroup<TailSegment>
{
	
	var position:FlxPoint;
	
	public function new()
	{
		super();
		position = FlxPoint.get();
		for (i in 0...64)
			add(new TailSegment());
	}
	
	override public function update(elapsed:Float):Void 
	{
		position.set(PlayState.i.nimbus.x, PlayState.i.nimbus.y + 3);
		fire();
		super.update(elapsed);
	}
	
	public function fire():Void
	{
		if (getFirstAvailable() != null)
			getFirstAvailable().fire(position);
	}
	
}

class TailSegment extends FlxSprite
{
	
	public function new()
	{
		super();
		exists = false;
		loadGraphic("assets/images/tailsegment.png");
	}
	
	public function fire(_pos:FlxPoint):Void
	{
		scale.y = 1;
		setPosition(_pos.x, _pos.y);
		velocity.x = -400;
		exists = true;
	}
	
	override public function update(elapsed:Float):Void 
	{
		scale.y = ZMath.clamp(scale.y -= 0.02, 0.3, 1);
		
		if (x < -16)
			kill();
		super.update(elapsed);
	}
	
}

class BackGround extends FlxGroup
{
	
	var ocean:FlxSprite;
	var sun:FlxSprite;
	
	var sparkles_1:Sparkles;
	var sparkles_2:Sparkles;
	var sparkles_3:Sparkles;
	
	var shadows:FlxSpriteGroup;
	
	var wave:FlxSprite;
	var sub_wave:FlxSprite;
	
	var blackground:FlxSprite;
	
	public function new()
	{
		super();
		
		blackground = new FlxSprite(0, 0);
		blackground.makeGraphic(FlxG.width, FlxG.height, 0xff000000);
		add(blackground);
		blackground.alpha = 0;
		
		sun = new FlxSprite(FlxG.width * 0.75, FlxG.height * 0.25);
		sun.makeGraphic(32, 32, 0x00ffffff);
		FlxSpriteUtil.drawCircle(sun);
		add(sun);
		
		ocean = new FlxSprite();
		ocean.makeGraphic(FlxG.width, FlxG.height, 0x00ffffff);
		FlxSpriteUtil.drawRect(ocean, 0, 0, FlxG.width, 1, 0xffffffff);
		FlxSpriteUtil.drawRect(ocean, 0, 1, FlxG.width, 7, 0xff639bff);
		FlxSpriteUtil.drawRect(ocean, 0, 8, FlxG.width, FlxG.height - 8, 0xff5b6ee1);
		add(ocean);
		
		shadows = new FlxSpriteGroup();
		add(shadows);
		
		sparkles_1 = new Sparkles(30, FlxRect.get(0, 0, FlxG.width, 8));
		sparkles_2 = new Sparkles(2, FlxRect.get(FlxG.width * 0.75 - 64, 0, 96, 64));
		sparkles_3 = new Sparkles(1, FlxRect.get(FlxG.width * 0.75 - 16, 0, 32, 96));
		
		add(sparkles_1);
		add(sparkles_2);
		add(sparkles_3);
		
		sub_wave = new FlxSprite(0, FlxG.height - 60);
		sub_wave.loadGraphic("assets/images/wave.png", true, 128, 48);
		sub_wave.animation.add("0", [4, 5, 6, 7], 20);
		sub_wave.animation.add("1", [8, 9, 10, 11], 25);
		sub_wave.origin.set(128, 48);
		sub_wave.scale.set(1.5, 0);
		PlayState.i.ui.add(sub_wave);
		
		wave = new FlxSprite(0, FlxG.height - 58);
		wave.loadGraphic("assets/images/wave.png", true, 128, 48);
		wave.animation.add("0", [4, 5, 6, 7], 20);
		wave.animation.add("1", [8, 9, 10, 11], 25);
		wave.origin.set(128, 48);
		wave.scale.set(1.5, 0);
		PlayState.i.ui.add(wave);
	}
	
	public function flash():Void
	{
		blackground.alpha = 1;
	}
	
	public function add_shadow(_parent:FlxObject):Void
	{
		shadows.add(new Shadow(_parent));
	}
	
	override public function update(elapsed:Float):Void 
	{
		blackground.alpha += (0 - blackground.alpha) * 0.1;
		
		ocean.y = ZMath.map(PlayState.i.caveman.y, 0, FlxG.height, FlxG.height * 0.8, FlxG.height * 0.7);
		
		sparkles_1.spawn_rect.y = sparkles_2.spawn_rect.y = sparkles_3.spawn_rect.y = ZMath.map(PlayState.i.caveman.y, 0, FlxG.height, FlxG.height * 0.8, FlxG.height * 0.7);
		
		sun.y = ZMath.map(PlayState.i.caveman.y, 0, FlxG.height, FlxG.height * 0.3, FlxG.height * 0.25);
		
		wave.x += (PlayState.i.nimbus.x - 100 - wave.x) * 0.1;
		
		if (PlayState.i.nimbus.y > FlxG.height * 0.825)
			wave.scale.y += (1 - wave.scale.y) * 0.025;
		else if (PlayState.i.nimbus.y > FlxG.height * 0.75)
			wave.scale.y += (0.5 - wave.scale.y) * 0.025;
		else
			wave.scale.y += (0 - wave.scale.y) * 0.025;
		wave.scale.y > 0.1 ? wave.animation.play("1") : wave.animation.play("0");
		
		sub_wave.x += (PlayState.i.nimbus.x - 180 - sub_wave.x) * 0.1;
		sub_wave.scale.y += PlayState.i.nimbus.y > FlxG.height * 0.8 ? (0.5 - sub_wave.scale.y) * 0.025 : (0 - sub_wave.scale.y) * 0.025;
		sub_wave.scale.y > 0.1 ? sub_wave.animation.play("1") : sub_wave.animation.play("0");
		
		if (PlayState.i.nimbus.y > FlxG.height * 0.825)
			PlayState.i.fg_poofs.fire(FlxPoint.get(wave.x + ZMath.randomRange(80, 128), wave.y + ZMath.randomRange(16, 48)), ZMath.velocityFromAngle(ZMath.randomRange(180, 320), ZMath.randomRange(150, 250)), ZMath.randomRangeInt(2, 7));
		
		super.update(elapsed);
	}
	
}

class Shadow extends FlxSprite
{
	
	var parent:FlxObject;
	
	public function new(_parent:FlxObject)
	{
		super(0, FlxG.height - 20, "assets/images/shadow.png");
		parent = _parent;
		offset.set(8, 6);
	}
	
	override public function update(elapsed:Float):Void 
	{
		x = parent.getMidpoint().x;
		scale.set(ZMath.randomRange(0.75, 2), ZMath.randomRange(0.75, 1));
		super.update(elapsed);
	}
	
}

class Sparkles extends FlxTypedGroup<Sparkle>
{
	
	public var spawn_rect:FlxRect;
	var timer:Int;
	var timer_amt:Int;
	
	public function new(_timer:Int, _spawn_rect:FlxRect)
	{
		super();
		
		timer_amt = _timer;
		spawn_rect = _spawn_rect;
		
		for (i in 0...32)
			add(new Sparkle());
	}
	
	public function fire():Void
	{
		if (getFirstAvailable() != null)
			getFirstAvailable().fire(
				FlxPoint.get(
					ZMath.randomRange(spawn_rect.x, spawn_rect.x + spawn_rect.width),
					ZMath.randomRange(spawn_rect.y, spawn_rect.y + spawn_rect.height)
				)
			);
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (timer == 0)
		{
			fire();
			timer = timer_amt;
		}
		else if (timer > 0)
			timer--;
		super.update(elapsed);
	}
	
}

class Sparkle extends FlxSprite
{
	
	public function new()
	{
		super();
		exists = false;
		makeGraphic(1, 1);
	}
	
	public function fire(_pos:FlxPoint):Void
	{
		setPosition(_pos.x, _pos.y);
		scale.x = ZMath.randomRange(4, 16);
		scale.y = ZMath.randomRange(0, 2);
		velocity.x = -10 * ZMath.map(y, FlxG.height * 0.7, FlxG.height, 0, 100);
		exists = true;
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (scale.y > 0)
			scale.y -= 0.25;
		else
			kill();
		super.update(elapsed);
	}
	
}

class ReticleStuff extends FlxGroup
{
	
	var offset_angle:Float = -45;
	/*var wave_amt:Float = 90;
	var bits_in_wave:Int = 6;*/
	var bits_before_reticle:Int = 5;
	var aiming_radius:Float = 48;
	/*var aim_speed:Int = 2;
	var overshoot:Float = 5;*/
	var current_angle:Float;
	/*var direction:Int = -1;*/
	var reticle:FlxSprite;
	/*var wave_bits:FlxSpriteGroup;*/
	var aim_bits:FlxSpriteGroup;
	var cursor:Cursor;
	var activated:Bool = false;
	
	public function new()
	{
		super();
		
		/*wave_bits = new FlxSpriteGroup();
		for (i in 0...bits_in_wave)
		{
			var bit = new FlxSprite(0, 0, "assets/images/bit.png");
			bit.offset.set(2, 2);
			wave_bits.add(bit);
		}
		add(wave_bits);*/
		
		aim_bits = new FlxSpriteGroup();
		for (i in 0...bits_before_reticle)
		{
			var bit = new FlxSprite(0, 0, "assets/images/bit.png");
			bit.offset.set(2, 2);
			aim_bits.add(bit);
		}
		add(aim_bits);
		
		reticle = new FlxSprite(0, 0, "assets/images/reticle.png");
		reticle.offset.set(8, 8);
		add(reticle);
		
		cursor = new Cursor();
		PlayState.i.ui.add(cursor);
		
		stop();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		/*current_angle += direction * aim_speed;
		if (current_angle > offset_angle + wave_amt * 0.5 || current_angle < offset_angle - wave_amt * 0.5)
			direction *= -1;*/
		
		current_angle = ZMath.angleBetween(cursor.get_that_origin_buddy(), PlayState.i.caveman.getMidpoint());
		aiming_radius = ZMath.clamp(ZMath.distance(cursor.get_that_origin_buddy(), PlayState.i.caveman.getMidpoint()), 16, 64);
		
		var _reticle_pos = ZMath.placeOnCircle(PlayState.i.caveman.getMidpoint(), current_angle, aiming_radius);
		reticle.setPosition(_reticle_pos.x, _reticle_pos.y);
		
		for (i in 1...(bits_before_reticle))
		{
			var _pos = ZMath.getMidPoint(PlayState.i.caveman.getMidpoint(), _reticle_pos, 100 / (bits_before_reticle) * i);
			aim_bits.members[i].setPosition(_pos.x, _pos.y);
		}
		
		/*for (i in  0...bits_in_wave)
		{
			var _pos = ZMath.placeOnCircle(PlayState.i.caveman.getMidpoint(), (offset_angle - wave_amt * 0.5) + (wave_amt / (bits_in_wave - 1) * i), aiming_radius);
			wave_bits.members[i].setPosition(_pos.x, _pos.y);
		}*/
		
		/*if (PlayState.i.state != 0 && PlayState.i.state != 1)
		{
			if (FlxG.keys.justPressed.UP)
			{
				offset_angle = 270;
				start(1);
			}
			if (FlxG.keys.justPressed.DOWN)
			{
				offset_angle = 90;
				start();
			}
			if (FlxG.keys.justPressed.LEFT)
			{
				offset_angle = 180;
				start(1);
			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				offset_angle = 0;
				start();
			}
		}
		else
			offset_angle = 315;*/
		
		cursor.clicked = activated && FlxG.mouse.pressed;
	}
	
	public function start(_direction:Int = -1):Void
	{
		exists = true;
		/*current_angle = offset_angle;
		direction = _direction;*/
	}
	
	public function stop():AnglePower
	{
		exists = false;
		return {angle:current_angle, power:ZMath.map(aiming_radius, 16, 48, 0, 1)};
	}
	
	public function get_current_angle():AnglePower
	{
		return {angle:current_angle, power:ZMath.map(aiming_radius, 16, 48, 0, 1)};
	}
	
	public function activate(_active:Bool):Void
	{
		activated = _active;
	}
	
}

class Poofs extends FlxTypedGroup<Poof>
{
	
	public function new(_amt:Int, _color:Array<Int>)
	{
		super();
		
		for (i in 0..._amt)
			add(new Poof(_color[ZMath.randomRangeInt(0, _color.length - 1)]));
	}
	
	public function fire(_p:FlxPoint, _v:FlxPoint, _s:Int):Void
	{
		if (getFirstAvailable() != null)
			getFirstAvailable().fire(_p, _v, Math.floor(ZMath.clamp(_s, 0, 7)));
	}
	
}

class Poof extends FlxSprite
{
	
	public function new(_color:Int)
	{
		super();
		exists = false;
		loadGraphic("assets/images/poof.png", true, 16, 16);
		animation.add("0", [7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("1", [6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("2", [5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("3", [4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("4", [3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("5", [2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("6", [1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		animation.add("7", [0, 1, 2, 3, 4, 5, 6, 6, 7, 7, 7, 8, 8, 8, 8], 30, false);
		offset.set(8, 8);
		color = _color;
		
		acceleration.x = -800;
		drag.set(980, 980);
	}
	
	public function fire(_p:FlxPoint, _v:FlxPoint, _s:Int):Void
	{
		setPosition(_p.x, _p.y);
		velocity.set(_v.x, _v.y);
		animation.play("" + _s);
		exists = true;
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (animation.finished)
			kill();
		super.update(elapsed);
	}
	
}

class Cursor extends FlxSpriteGroup
{
	
	public var clicked:Bool;
	var bit_amt:Int = 8;
	var angloni:Float;
	var angular_v:Float;
	var radius:Float;
	var cur_radius:Float;
	var origino:FlxPoint;
	
	public function new()
	{
		super();
		
		for (i in 0...bit_amt)
		{
			var b = new FlxSprite(0, 0, "assets/images/bit.png");
			b.offset.set(2, 2);
			add(b);
		}
	}
	
	override public function update(elapsed:Float):Void 
	{
		angloni = ZMath.toRelativeAngle(angloni);
		origino = FlxG.mouse.getPosition();
		
		for (i in 0...members.length)
		{
			var _p = ZMath.placeOnCircle(origino, angloni + 360 / bit_amt * i, cur_radius);
			members[i].setPosition(_p.x, _p.y);
		}
		
		if (clicked)
		{
			angular_v = ZMath.clamp(angular_v + 0.25, 0, 4);
			radius = 12;
		}
		else
		{
			angular_v = 0;
			radius = 8;
		}
		
		angloni += angular_v;
		cur_radius += (radius - cur_radius) * 0.1;
		
		super.update(elapsed);
	}
	
	public function get_that_origin_buddy():FlxPoint
	{
		return origino;
	}
	
}

class UILayer extends FlxGroup
{
	
	public function new()
	{
		super();
	}
	
}

class Mines extends FlxTypedGroup<Mine>
{
	
	var timer:Int = 300;
	var timer_amt:Int = 800;
	
	public function new()
	{
		super();
		for (i in 0...20)
			add(new Mine());
	}
	
	public function fire():Void
	{
		if (getFirstAvailable() != null)
			getFirstAvailable().fire();
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (timer == 0)
		{
			fire();
			timer = timer_amt;
			timer_amt = Math.floor(ZMath.clamp(timer_amt - 10, 60, 900));
		}
		else if (timer > 0)
			timer--;
		super.update(elapsed);
	}
	
}

class Mine extends FlxSprite
{
	
	var explosions:Explosions;
	
	public function new()
	{
		super();
		loadGraphic("assets/images/mine.png", true, 16, 16);
		animation.add("play", [0, 1, 2, 3, 4, 5, 6, 7], 15);
		exists = false;
		PlayState.i.background.add_shadow(this);
		velocity.set( -20, -20);
		FlxTween.tween(velocity, {y:20}, ZMath.randomRange(1.5, 2.5), {type:FlxTween.PINGPONG, ease:FlxEase.sineInOut});
		explosions = new Explosions();
		setSize(8, 8);
		offset.set(4, 4);
	}
	
	public function fire():Void
	{
		var _p = FlxPoint.get(FlxG.width + 8, ZMath.randomRange(32, FlxG.height - 64));
		last.set(_p.x, _p.y);
		setPosition(_p.x, _p.y);
		exists = true;
		animation.play("play", true);
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (x < -20)
			kill();
		super.update(elapsed);
	}
	
	public function explode():Void
	{
		var m = getMidpoint();
		explosions.fire(m, 3);
		for (i in 1...9)
			new FlxTimer().start(0.05 * i).onComplete = function(t:FlxTimer):Void
			{
				explosions.fire(FlxPoint.get(m.x + ZMath.randomRange(-16,16), m.y + ZMath.randomRange(-16,16)), 1);
			}
		kill();
	}
	
}

class Explosions extends FlxTypedGroup<Explosion>
{
	
	public function new ()
	{
		super();
		for (i in 0...8)
			add(new Explosion());
	}
	
	public function fire(_p:FlxPoint, _s:Float):Void
	{
		PlayState.i.background.flash();
		PlayState.i.bg_poofs.fire(_p, ZMath.velocityFromAngle(ZMath.randomRange(0, 360), ZMath.randomRange(150, 300)), 8);
		PlayState.i.bg_poofs.fire(_p, ZMath.velocityFromAngle(ZMath.randomRange(0, 360), ZMath.randomRange(150, 300)), 8);
		PlayState.i.bg_poofs.fire(_p, ZMath.velocityFromAngle(ZMath.randomRange(0, 360), ZMath.randomRange(150, 300)), 8);
		if (getFirstAvailable() != null)
			getFirstAvailable().fire(_p, _s);
	}
	
}

class Explosion extends FlxSprite
{
	
	public function new()
	{
		super();
		loadGraphic("assets/images/explosion.png", true, 32, 32);
		animation.add("play", [0, 1, 2, 3, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6], 30, false);
		exists = false;
		acceleration.x = -200;
		PlayState.i.explosion_layer.add(this);
		offset.set(16, 16);
	}
	
	public function fire(_p:FlxPoint, _s:Float):Void
	{
		setPosition(_p.x, _p.y);
		angle = ZMath.randomRange(0, 360);
		scale.set(_s, _s);
		animation.play("play");
		velocity.set();
		exists = true;
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (animation.finished)
			kill();
		super.update(elapsed);
	}
	
}

typedef AnglePower =
{
	angle:Float,
	power:Float
}

class GameOver extends FlxSubState
{
	
	var can_continue:Bool = false;
	
	public function new()
	{
		super();
		
		FlxTween.manager.active = false;
		
		var s = new FlxSprite();
		s.makeGraphic(FlxG.width, FlxG.height, 0x80ffd040);
		s.blend = BlendMode.HARDLIGHT;
		add(s);
		
		add(new FlxSprite(0, 0, "assets/images/gameover.png"));
		
		FlxG.camera.flash(0xffffffff, 0.2);
		
		new FlxTimer().start(0.5).onComplete = function(t:FlxTimer):Void
		{
			can_continue = true;
		}
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if ((FlxG.keys.justPressed.ANY || FlxG.mouse.justPressed) && can_continue)
		{
			FlxTween.manager.active = true;
			FlxG.resetState();
		}
	}
	
}

class Ufo extends FlxSprite
{
	
	public var _v_sin:Float = 200;
	var explosions:Explosions;
	
	public function new()
	{
		PlayState.i.ufos_on_screen++;
		super(FlxG.width + 32, -64);
		loadGraphic("assets/images/ufo.png", true, 40, 40);
		animation.add("play", [0, 1, 2, 3, 4, 5, 6, 7], 8);
		animation.play("play");
		offset.set(10, 10);
		setSize(20, 20);
		
		explosions = new Explosions();
		go_to_pos();
	}
	
	function go_to_pos(?t:FlxTimer):Void
	{
		FlxTween.tween(this, {x:ZMath.randomRange(150, FlxG.width - 40), y:ZMath.randomRange(16, 160)}, 4, {ease:FlxEase.backInOut});
		new FlxTimer().start(ZMath.randomRange(4, 8), go_to_pos);
	}
	
	var t = 1;
	
	override public function update(elapsed:Float):Void 
	{
		if (t == 0)
		{
			t = ZMath.randomRangeInt(5, 15);
			PlayState.i.bg_poofs.fire(FlxPoint.get(x, y + ZMath.randomRange(12,20)), FlxPoint.get(ZMath.randomRange( -100, -150), ZMath.randomRange(-16,16)), ZMath.randomRangeInt(3, 7));
		}
		else if (t > 0)
			t--;
		
		super.update(elapsed);
	}
	
	override public function kill():Void 
	{
		PlayState.i.ufos_on_screen--;
		explosions.fire(getMidpoint(), 3);
		super.kill();
	}
	
}