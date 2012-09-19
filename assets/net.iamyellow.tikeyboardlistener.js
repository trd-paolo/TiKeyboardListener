// if we don't do this, we'll get a linking error when building the app for release. why? 
// - this module uses TiUIScrollView
// - titanium compiler checks javascript files to find what are you using
// - if you don't use e.g. ScrollView, it won't compile sources
// if I find a better way, I'll change this, I really hate this kind of hacks
exports.createScrollView = Ti.UI.createScrollView;