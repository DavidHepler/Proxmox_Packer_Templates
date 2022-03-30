# Ubuntu 20.04.04 template creation with Packer

Usage:
  - rename the file ".auto.pkrvars.hcl.example" to ".auto.pkrvars.hcl"
  - the file /http/user-data needs to be edited:
    - Make sure that you fix the locale and keyboard layout
    - Change the username under identity/user to the user you want to use and defined as "var.username"
    - Create a password hash for key identity/password that you defined as "var.user_password". In Linux you could use the following command: "openssl passwd -6 -stdin <<< your-passsword"
     - edit the late-commands and replace "newuser" with the user defined in "var.username"

