$BLANK_CKL_SLIM_VERS = ""
$BLANK_CKL_FULL_VERS.Split('_') | foreach { switch -regex ($_) {"^RHEL$" {$BLANK_CKL_SLIM_VERS = "$_"} "^[0-9]$" {$BLANK_CKL_SLIM_VERS += "$_"} "^(V*R*)" { $BLANK_CKL_SLIM_VERS += "_$_" }}}

$BLANK_CKL_SLIM_VERS