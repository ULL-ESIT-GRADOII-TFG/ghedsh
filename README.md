#GITHUB EDUCATION SHELL

A command line program following the philosophy of GitHub Education.

##How does it works?

This program give you an interaction with Github like you was using your command line simulating a tree structure. Each level on the tree gives you several options of managing your Github account or your Organization.

Following the philosophy of Github Education, you can use this application to managing your own organization as a classroom where you can make assignments to your students using repository strategies.    

##First step: Oauth requirements.

Ir order to run this program, you need to make an **Access token** from Github with create and edit scope. When you run the program, it asks you the access token to identify yourself with no need to use your user and password.

##Running the program in your computer

You can run this program downloading this repository directly, but you need to setting the configure file. Rename the file *configure_template.json* to *configure.json* in **./lib/configure/.**

To start using the program, put "rake bash" or "rake" in your command line in the main folder of this program. You can invoke the binary file using the command *ghedsh*.

##Using the gem
Instead of download the program from the repository, you can download the gem **ghdesh** from rubygem.

``gem install ghdesh``

To run the app you need to call the binary file "ghesh" in your command line after install it.  

##Basic usage
Logged in our app you start set in your personal profile. There you can list your repositories, create repositories, see your organizations and other options that you can see using the command *help* in your command line. You can go inside of a specific organization with the command *cd* and start to managing itself. Its possible to create task for the members your organization, create teamworks and many options that you can see again with *help*. You can move and go back in the tree directory as it is possible in the github structure.

Levels
└── User
    ├── Organizations
    │   ├── Teams
    │   │    └── Team Repositories
    │   ├── Assignments
    │   └── Organization Repositories
    └── User Repositories


##Aditional information
[Github Education](https://education.github.com/)
