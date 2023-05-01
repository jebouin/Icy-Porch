<?php include("constants.php"); ?>
build.web._base.hxml

-D itch
-js bin/itch/<?php echo $gameId ?>.js
--cmd cp -t bin/itch/ bin/js/index.html bin/js/avatar.png bin/res.pak bin/js/style.css
--cmd cd bin/itch
--cmd zip -r ../itch.zip *
--cmd cd ../..