
var test = 'tab'; // possible values: 'win' | 'nav' | 'tab'

(function (keyboardListener) {
	var win, navWin, tabGroup;
	
	// ****************************************************************************************************************
	// containers

	win = Ti.UI.createWindow({
		backgroundColor: '#fff612'
	});
	
	if (test === 'nav') {
		navWin = Ti.UI.iOS.createNavigationWindow({
			window: win
		});
	}
	else if (test === 'tab') {
		var tab = Titanium.UI.createTab({
			icon: 'KS_nav_views.png',
			title: 'Tab 1',
			window: win
		});
		
		tabGroup = Titanium.UI.createTabGroup();
		tabGroup.addTab(tab);
	};	

	// ****************************************************************************************************************
	// window views 
	
	// the container view which should be resized
	var container = keyboardListener.createView({
		width: Ti.UI.FILL, height: Ti.UI.FILL,
		backgroundColor: '#fff612'
	});
	win.add(container);

	// a bottom cointaner view
	var toolbar = Ti.UI.createView({
		width: Ti.UI.FILL, height: 40,
		backgroundColor: '#ccc',
		bottom: 0
	}),
	trigger = Ti.UI.createTextField({
		height: 20,
		top: 10, left: 10, right: 70,
		backgroundColor: '#fff'
	}),
	blurBtn = Ti.UI.createButton({
		width: 50, height: 20,
		top: 10,
		right: 10,
		title: 'blur'
	});
	toolbar.add(trigger);
	toolbar.add(blurBtn);
	container.add(toolbar);

	// ****************************************************************************************************************
	// keyboard listener stuff

	container.addEventListener('keyboard:show', function (ev) {
		Ti.API.info('* keyboard height is ' + ev.keyboardHeight + ', and my height is now ' + ev.height);
	});
	container.addEventListener('keyboard:hide', function (ev) {
		Ti.API.info('* keyboard height was ' + ev.keyboardHeight + ', and my height is now ' + ev.height);
	});

	blurBtn.addEventListener('click', function () {
		trigger.blur();
	});

	// ****************************************************************************************************************
	// start the show
	if (tabGroup) {
		tabGroup.open();
		return;
	}
	
	if (navWin) {
		navWin.open();
		return;	
	}
	
	win.open();
})(require('net.iamyellow.tikeyboardlistener'));