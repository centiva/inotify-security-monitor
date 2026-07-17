# Server Configuration Guide



## Monitoring rules



Monitor:



✓ PHP files

✓ Configuration files

✓ Scripts

✓ Executable files



Avoid excluding:



- wp-config.php

- configuration.php

- .htaccess

- .user.ini

- PHP application directories





## WordPress example



WATCH_DIRS=(

"/home/site/public_html"

)



EXCLUDE_DIR_PATTERNS=(

"*/wp-content/cache/*"

"*/wp-content/uploads/*"

"*/vendor/*"

)





## Joomla example



WATCH_DIRS=(

"/home/site/public_html"

)



EXCLUDE_DIR_PATTERNS=(

"*/cache/*"

"*/tmp/*"

"*/administrator/cache/*"

)
