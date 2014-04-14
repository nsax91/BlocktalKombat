var scene, camera, renderer, controller;

/* @pjs preload="./pictures.jpg"; */
var pointsInScreen = [];
var MAX_PTS = 2;

function setupRenderer(){
	renderer = new THREE.WebGLRenderer({antialias: true});
	renderer.setSize(
		document.body.clientWidth,
		document.body.clientHeight
	);
	document.body.appendChild(renderer.domElement);
	renderer.clear();

	camera = new THREE.PerspectiveCamera(45, window.innerWidth/window.innerHeight, 0.10, 1000);
	camera.position.z = 500;
	camera.position.y = 100;
	camera.lookAt(new THREE.Vector3(0,300,0));

	scene = new THREE.Scene();
    
    /*
    // Basic Test
    var cube = new THREE.Mesh(
    	new THREE.CubeGeometry(50,50,50),
   		new THREE.MeshBasicMaterial({color: 0x000000})
   	);
   	scene.add(cube);
	*/
	
    renderer.render(scene, camera);
}

function processFrame(frame){
	var pointsInFrame = [];
	// Only process if we have identified hands.
	for (var index = 0; index < frame.hands.length; index++){
		var hand = frame.hands[index];
		var pos = hand.sphereCenter;
		var dir = hand.direction;

		/*
		var origin = new THREE.Vector3(pos[0], pos[1] - 30, pos[2]);
		var direction = new THREE.Vector3(dir[0], dir[1], dir[2]);

		var arrowObj = new THREE.ArrowHelper(origin, direction, 40, 0xf0f0f0);
        arrowObj.position = origin;
		arrowObj.setDirection(direction);

		pointsInFrame.push(arrowObj);
		*/
		pointsInFrame.push(pos);
	}

	return pointsInFrame;
}

function processResponse(frame){
	var pointsInFrame = processFrame(frame);

	for (var index = 0; index < pointsInFrame.length; index++){


		if(pointsInScreen.length > MAX_PTS){
			var pointToRemove = pointsInScreen.shift();
			//scene.remove(pointToRemove);
		}

		var pointToAdd = pointsInFrame[index];
		pointsInScreen.push(pointToAdd);
		//scene.add(pointToAdd);
		//console.log("Adding point to scene.");
		handMoved(pointToAdd[0], pointToAdd[1]);
		console.log("Got x:" + pointToAdd[0] + "y:" + pointToAdd[1] + "z:" + pointToAdd[2]);
	}

	//renderer.render(scene, camera);
}

function startListening(){
	//controller = new Leap.Controller();
	controller = new Leap.Controller({frameEventName: "deviceFrame"});

	controller.on(
		'deviceFrame',
		processResponse
	);

	controller.connect();
}

//$.ready(function(){
	//setupRenderer();
	startListening();
//});


float canv_w = 1900;
float canv_h = 1000;

float drum_w = 250;
float drum_h = 100;
float base_speed = 17;
float note_speed = base_speed;
float min_speed = 17;
float max_speed = 25;
int current_combo = 0;
int longest_combo = 0;

// Note Positions
float OVER_DRUM_0 = 75;
float OVER_DRUM_1 = 375;
float OVER_DRUM_2 = 675;
float OVER_DRUM_3 = 1025;
float OVER_DRUM_4 = 1325;
float OVER_DRUM_5 = 1625;
float[] LEFT_DRUMS = [OVER_DRUM_0, OVER_DRUM_1, OVER_DRUM_2];
float[] RIGHT_DRUMS = [OVER_DRUM_3, OVER_DRUM_4, OVER_DRUM_5];

int score = 0;
int max_lives = 5000;
int lives = max_lives;
PImage bg;

void setup() {
	size(canv_w,canv_h);

	notes[0] = new Note(OVER_DRUM_3,0,200,70,255,255,255, true);
	notes[1] = new Note(OVER_DRUM_0,0,200,70,255,255,255, false);
	for (int i = 2; i<notes.length; i++) {
		notes[i] = new Note();
	}
	bg = loadImage("./pictures.jpg");	
}

// Set up Drums
Drum d0 = new Drum(50,850,drum_w,drum_h);
Drum d1 = new Drum(350,850,drum_w,drum_h);
Drum d2 = new Drum(650,850,drum_w,drum_h);
Drum d3 = new Drum(1000,850,drum_w,drum_h);
Drum d4 = new Drum(1300,850,drum_w,drum_h);
Drum d5 = new Drum(1600,850,drum_w,drum_h);
Drum[] drums = {d0,d1,d2,d3, d4, d5};

// Set up Notes
Note[] notes = new Note[15];

// Set up Drumsticks
DrumStick ds2 = new DrumStick(0,0,255);
Drumstick ds1 = new DrumStick(1900,0,255);

// Text Colors
float text_r = 128;
float text_g = 0;
float text_b = 0;

void draw_score() {
	textSize(50);
	fill(text_r,text_g,text_b);
	text("Score: " + score, 60, 60);
}

void draw_speed() {
	textSize(50);
	fill(text_r,text_g,text_b);
	text("Level: " + (note_speed-16), 60, 120);
}

void draw_lives() {
	textSize(50);
	fill(text_r,text_g,text_b);
	text("Lives: " + lives, 1600, 60);
}

void draw_combo() {
	textSize(50);
	fill(text_r,text_g,text_b);
	text("Combo: " + current_combo, 1600, 120);
}

void update_score(){
	score += 100;
}

void update_speed(){
	if ((lives % 4 == 0) && (note_speed > min_speed)) {
		note_speed--;
	}
	if (((score % 2000) == 0) && (note_speed < max_speed)){
		note_speed++;
	}	
}

void reduce_life(){
	lives -= 1;
	if (lives < 0) {
		alert("Game Over!!\nLongest block streak:" + longest_combo);
		lives = max_lives;
		score = 0;
		longest_combo = 0;
	}		
}

void draw() {
	background(bg);
	draw_score();
	draw_lives();
	draw_speed();
	draw_combo();
	
	// Draw the Drums
	for (int i = 0; i<drums.length; i++) {
		drums[i].draw();
	}

	// Draw the Notes
	for (int i = 0; i<notes.length; i++) {
		notes[i].update();
		notes[i].draw();
	}

	// Draw Drumsticks
	ds1.draw();
	ds2.draw();

	// Check with Drums are Stuck
	ArrayList drums_hit = determine_drums_hit();

	// Highlight Them
	highlight_drums(drums_hit);

	// Drum + Note + Drumstick Collisions
	void drum_note_stick_collision(drums_hit);

}


void drum_note_stick_collision(ArrayList drums_hit) {
	for (int i = 0; i<drums_hit.size(); i++) {
		Drum d = drums[drums_hit.get(i)];		

		for (int j = 0; j<notes.length; j++) {
			if (!notes[j].exists) {				
				continue;
			}

			if (drum_note_collision(d,notes[j])) {
				if(notes[j].played == false){
					update_score();
					notes[j].played = true;
					update_speed();	
				}				
			}
 		}
	}
}

boolean drum_note_collision(Drum d, Note n) {
	if (d.x > n.x+n.width) {return false;}
	if (d.x+d.width < n.x) {return false;}
	if (d.y > n.y+n.height) {return false;}
	if (d.y+d.height < n.y) {return false;}
	return true;
}

ArrayList determine_drums_hit() {
	ArrayList drums_hit = new ArrayList();
	for (int i = 0; i<drums.length; i++) {
		boolean hit_by_ds1 = true;
		if (ds1.x-ds1.rad > drums[i].x+drums[i].width) {hit_by_ds1 = false;}
		if (ds1.x+ds1.rad < drums[i].x) {hit_by_ds1 = false;}
		if (ds1.y+ds1.rad < drums[i].y) {hit_by_ds1 = false;}
		if (ds1.y-ds1.rad > drums[i].y+drums[i].height) {hit_by_ds1 = false;}

		boolean hit_by_ds2 = true;
		if (ds2.x-ds2.rad > drums[i].x+drums[i].width) {hit_by_ds2 = false;}
		if (ds2.x+ds2.rad < drums[i].x) {hit_by_ds2 = false;}
		if (ds2.y+ds2.rad < drums[i].y) {hit_by_ds2 = false;}
		if (ds2.y-ds2.rad > drums[i].y+drums[i].height) {hit_by_ds2 = false;}

		if (hit_by_ds1 || hit_by_ds2) {
			drums_hit.add(i);
		}
	}

	return drums_hit;	
}

void highlight_drums(ArrayList drums_hit) {	
	for (int i = 0; i<drums_hit.size(); i++) {
		drums[drums_hit.get(i)].highlight = true;
	}	
}

void moveDrumStick(float x, float y, Drumstick ds) {
	maxX = 250;
	if(x > maxX){
		ds.x = 1900;
	}
	else{
		ds.x = (x+maxX)*1900/(2*maxX);
	}
	//ds1.y = 1000-y;
	ds.y = 900;
}

void handMovedRight(float x, float y){
	moveDrumStick(x, y, ds1);
}

void handMovedLeft(float x, float y){
	moveDrumStick(x, y, ds2);
}

function handMoved(x,y) {
	maxX = 250;
	if(x > 0){
		handMovedRight(x, y);
	}
	else{
		handMovedLeft(x, y);
	}
	//ds1.y = 1000-y;
}

class Note {
	float x,y,width,height;
	float red,green,blue;
	boolean exists = true;
	boolean played = false;
	boolean is_left = true;

	Note(float xp,float yp,float w,float h,float r,float g,float b, boolean parity) {
		x = xp;
		y = yp;
		width = w;
		height = h;
		red = r;
		green = g;
		blue = b;
		exists = true;
		is_left = parity;
	}

	Note() {
		exists = false;
	}

	void reset() {		
		float seed = random(0,1);
		float[] over_drum;
		if(is_left)
			over_drum = LEFT_DRUMS;
		else
			over_drum = RIGHT_DRUMS;

		if (seed < 0.33) {
			x = over_drum[0];
			y = 0;
		}
		else if (seed < 0.67) {
			x = over_drum[1];
			y = 0;
		}
		else {
			x = over_drum[2];
			y = 0;
		}
			

		if(!played){
			reduce_life();
			if(longest_combo < current_combo)
				longest_combo = current_combo;
			current_combo = 0;
		}
		else
			current_combo++;
			
		played = false;
	}

	void update() {
		if (!exists) {return;}
		y += note_speed;
		if (y > canv_h) {
			reset();
		}
	}

	void draw() {
		if (!exists) {return;}

		if (played) {
			fill(170,0,0,150,10);
		}
		else {
			fill(red,green,blue,150,10);	
		}
		rect(x,y,width,height);
	}
}

class Drum {
	float x,y,width,height;
	float red = 5;
	float green = 58;
	float blue = 97;	
	boolean highlight = false;	

	Drum(float xp, float yp, float w, float h) {
		x = xp;
		y = yp;
		width = w;
		height = h;
	}

	void draw() {
		if (highlight) {
			strokeWeight(15);
			stroke(red,green,blue);
			highlight = false;
		}

		fill(red,green,blue);
		rect(x,y,width,height,10);
		noStroke();
	}
}

class DrumStick {
	float x,y,rad;
	float red,green,blue;

	DrumStick(float xp, float yp, float r) {
		x = xp;
		y = yp;
		rad = 50;
		red = r;
		green = 102;
		blue = 0;
	}

	void draw() {
		fill(red,green,blue,150);
		ellipse(x,y,rad,rad);
	}
}



















