package;

#if mobile
import cpp.Void;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.FlxTrail;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import flixel.util.FlxSpriteUtil;
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
	
	public var background:BackGround;
	
	var dt:FlxText;
	
	override public function create():Void
	{
		i = this;
		
		FlxG.mouse.visible = false;
		bgColor = 0xff5fcde4;
		
		background = new BackGround();
		add(background);
		
		bg_poofs = new Poofs(20, 0xff9badb7);
		add(bg_poofs);
		
		reticle = new ReticleStuff();
		add(reticle);
		
		caveman = new CaveMan();
		nimbus = new Nimbus();
		
		add(caveman);
		add(nimbus);
		
		fg_poofs = new Poofs(20, 0xffffffff);
		add(fg_poofs);
		
		cloud_start();
		
		dt = new FlxText(10, 10);
		add(dt);
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
		
		#if debug
		dt.text = "" + state;
		if (FlxG.keys.justPressed.R)
			FlxG.resetState();
		#end
	}
	
	function cloud_start():Void
	{
		nimbus.controlling = true;
		caveman.set_on_nimbus();
		state = 0;
	}
	
	function cloud_update():Void
	{
		if (FlxG.keys.justPressed.SPACE)
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
		if (FlxG.keys.justReleased.SPACE)
			cannonball_start();
	}
	
	function cannonball_start():Void
	{
		caveman.cannonball(reticle.get_current_angle());
		reticle.stop();
		nimbus.controlling = true;
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
	
}

class WindowBouncer extends FlxSprite
{
	
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
		if (y < 0)
			velocity.y = Math.abs(velocity.y);
		
		super.update(elapsed);
	}
	
	function hit_bottom():Void
	{
		velocity.y = -Math.abs(velocity.y);
	}
	
}

class CaveMan extends WindowBouncer
{
	
	var on_nimbus:Bool;
	var in_danger:Bool = false;
	
	public function new()
	{
		super(68, FlxG.height * 0.5 - 16);
		loadGraphic("assets/images/caveman.png", true, 16, 16);
		animation.add("idle", [0, 1, 2, 3, 4, 5], 12);
		animation.add("fall", [6, 7, 8, 9], 10);
		animation.add("cannonball", [17, 16, 15, 14, 13, 12, 11, 10]);
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		if (on_nimbus)
			setPosition(PlayState.i.nimbus.x + 4, PlayState.i.nimbus.y - 16);
		acceleration.y = on_nimbus ? 0 : 300;
		allowCollisions = on_nimbus ? 0x0000 : 0x1111;
		if (in_danger)
			danger_mode();
	}
	
	function danger_mode():Void
	{
		scale.y = FlxMath.signOf(velocity.y);
	}
	
	override function hit_bottom():Void 
	{
		if (!in_danger)
		{
			in_danger = true;
			velocity.set(velocity.x * 0.5, -350);
			animation.play("fall");
		}
	}
	
	public function set_on_nimbus():Void
	{
		scale.y = 1;
		last.set(PlayState.i.nimbus.x + 4, PlayState.i.nimbus.y - 16);
		setPosition(PlayState.i.nimbus.x + 4, PlayState.i.nimbus.y - 16);
		on_nimbus = true;
		in_danger = false;
		animation.play("idle");
	}
	
	public function cannonball(_angle:Float):Void
	{
		on_nimbus = false;
		var _v = ZMath.velocityFromAngle(_angle, 300);
		velocity.set(_v.x, _v.y);
		animation.play("cannonball");
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
		maxVelocity.set(120, 120);
		drag.set(100, 100);
		PlayState.i.add(new NimbusTail());
		
		allowCollisions = 0x0100;
	}
	
	override public function update(elapsed:Float):Void 
	{
		if (controlling)
			controls();
		wiggle();
		super.update(elapsed);
	}
	
	var accel_amt:Float = 1000;
	
	function controls():Void
	{
		acceleration.set();
		if (FlxG.keys.pressed.UP)
			acceleration.y -= accel_amt;
		if (FlxG.keys.pressed.DOWN)
			acceleration.y += accel_amt;
		if (FlxG.keys.pressed.LEFT)
			acceleration.x -= accel_amt;
		if (FlxG.keys.pressed.RIGHT)
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
		scale.y -= 0.01;
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
	
	public function new()
	{
		super();
		
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
	}
	
	public function add_shadow(_parent:FlxObject):Void
	{
		shadows.add(new Shadow(_parent));
	}
	
	override public function update(elapsed:Float):Void 
	{
		ocean.y = ZMath.map(PlayState.i.caveman.y, 0, FlxG.height, FlxG.height * 0.8, FlxG.height * 0.7);
		
		sparkles_1.spawn_rect.y = sparkles_2.spawn_rect.y = sparkles_3.spawn_rect.y = ZMath.map(PlayState.i.caveman.y, 0, FlxG.height, FlxG.height * 0.8, FlxG.height * 0.7);
		
		sun.y = ZMath.map(PlayState.i.caveman.y, 0, FlxG.height, FlxG.height * 0.3, FlxG.height * 0.25);
		
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
		alpha = 0.25;
	}
	
	override public function update(elapsed:Float):Void 
	{
		x = parent.getMidpoint().x;
		scale.set(ZMath.randomRange(0.75, 1.5), ZMath.randomRange(0.9, 1.1));
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
	var wave_amt:Float = 90;
	var bits_in_wave:Int = 6;
	var bits_before_reticle:Int = 4;
	var aiming_radius:Float = 48;
	var aim_speed:Int = 2;
	var overshoot:Float = 5;
	
	var current_angle:Float;
	var direction:Int = -1;
	
	var reticle:FlxSprite;
	var wave_bits:FlxSpriteGroup;
	var aim_bits:FlxSpriteGroup;
	
	public function new()
	{
		super();
		
		wave_bits = new FlxSpriteGroup();
		for (i in 0...bits_in_wave)
		{
			var bit = new FlxSprite(0, 0, "assets/images/bit.png");
			bit.offset.set(2, 2);
			wave_bits.add(bit);
		}
		add(wave_bits);
		
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
		
		stop();
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		current_angle += direction * aim_speed;
		if (current_angle > offset_angle + wave_amt * 0.5 || current_angle < offset_angle - wave_amt * 0.5)
			direction *= -1;
		
		var _reticle_pos = ZMath.placeOnCircle(PlayState.i.caveman.getMidpoint(), current_angle, aiming_radius);
		reticle.setPosition(_reticle_pos.x, _reticle_pos.y);
		
		for (i in 1...(bits_before_reticle))
		{
			var _pos = ZMath.getMidPoint(PlayState.i.caveman.getMidpoint(), _reticle_pos, 100 / (bits_before_reticle) * i);
			aim_bits.members[i].setPosition(_pos.x, _pos.y);
		}
		
		for (i in  0...bits_in_wave)
		{
			var _pos = ZMath.placeOnCircle(PlayState.i.caveman.getMidpoint(), (offset_angle - wave_amt * 0.5) + (wave_amt / (bits_in_wave - 1) * i), aiming_radius);
			wave_bits.members[i].setPosition(_pos.x, _pos.y);
		}
		
		if (PlayState.i.state != 0 && PlayState.i.state != 1)
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
			offset_angle = 315;
		
	}
	
	public function start(_direction:Int = -1):Void
	{
		exists = true;
		current_angle = offset_angle;
		direction = _direction;
	}
	
	public function stop():Float
	{
		exists = false;
		return current_angle;
	}
	
	public function get_current_angle():Float
	{
		return current_angle;
	}
	
}

class Poofs extends FlxTypedGroup<Poof>
{
	
	public function new(_amt:Int, _color:Int)
	{
		super();
		
		for (i in 0..._amt)
			add(new Poof(_color));
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