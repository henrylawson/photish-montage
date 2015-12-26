$(function() {
var $container  = $('.am-container'),
    $imgs   = $container.find('img').hide(),
    totalImgs = $imgs.length,
    cnt     = 0;

$imgs.each(function(i) {
  var $img  = $(this);
  $('<img/>').load(function() {
    ++cnt;
    if( cnt === totalImgs ) {
      $imgs.show();
      $container.montage({
        minw : 400,
        alternateHeight : true,
        alternateHeightRange : {
          min : 200,
          max : 350
        },
        margin : 8,
        fillLastRow : true
      });
    }
  }).attr('src',$img.attr('src'));
});
});

