<?php include("constants.php"); ?>
build.web._base.hxml

-lib gjCloud
-D gamejolt
-js bin/gamejolt/<?php echo $gameId ?>.js
--cmd cp -t bin/gamejolt/ bin/js/index.html bin/js/avatar.png bin/res.pak
--cmd cd bin/gamejolt
--cmd zip -r ../gamejolt.zip *
--cmd cd ../..