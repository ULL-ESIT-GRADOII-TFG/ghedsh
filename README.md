#GITHUB EDUCATION SHELL

A command line program following the philosophy of GitHub Education.

##How does it work?

This program give you an interaction with Github like you was using your command line simulating a tree structure. Each level on the tree gives you several options of managing your Github account or your Organization.

Following the philosophy of Github Education, you can use this application to managing your own organization as a classroom where you can make assignments to your students using repository strategies.    

##First step: Oauth requirements.

Ir order to run this program, you need to make an **Access token** from Github with create and edit scope. When you run the program, it asks you the access token to identify yourself with no need to use your user and password.

##Running the program in your computer

To start using the program, put "rake bash" or "rake" in your command line in the main folder of this program. You can invoke the binary file using the command *ghedsh*.

##Using the gem
Instead of download the program from the repository, you can download the gem **ghdesh** from rubygem.

``gem install ghdesh``

To run the app you need to call the binary file "ghedsh" in your command line after install it.  

###ghedsh executable options

'-t' or '--token token'. Provides a github access token by argument.

'-u', '--user user'. Change your user from your users list

'-v', '--version'. Show the current version of GHEDSH

'-h', '--help'. Displays Help

This program creates a directory called *.ghedsh* in your home with all configuration files that it needs.


##Basic usage
Logged in our app you start set in your personal profile. There you can list your repositories, create repositories, see your organizations and other options that you can see using the command *help* in your command line. You can go inside of a specific organization with the command *cd* and start to managing itself. Its possible to create task for the members your organization, create teamworks and many options that you can see again with *help*. You can move and go back in the tree directory as it is possible in the github structure.

```
Levels
└── User
    ├── Organizations
    │   ├── Teams
    │   │    └── Team Repositories
    │   ├── Assignments
    │   └── Organization Repositories
    └── User Repositories
```

##Lista de comandos


```sh
cd <nombre>
```

Va a la ruta correspondiente con el nombre dado. La ruta puede ser un repositorio, una organizacion, o un equipo. Si el usuario se encuentra en la raiz, el comando primero buscara una organizacion con el nombre dado, y si no la encuentra buscara un repositorio, y si el usuario esta situado en una organizacion el programa buscara primero un equipo y despues un repositorio.

Si queremos ir directamente a un repositorio es posible usar `` cd repo <nombre> ``


```sh
! <comando>
```
Ejecuta un comando en la terminal donde se este ejecutando el programa.

```sh
help
```
Muestra las opciones disponibles segun el ambito en el que la ayuda sea invocada.
```sh
exit
```
Con este comando el usuario sale de ghedsh.

```sh
orgs
```
Estando en el ambito del usuario, mostrara la lista de Organizaciones a las que pertenece el usuario.

```sh
repos
```

Muestra la lista de todos los repositorios disponibles del usuario segun el ambito. Si estamos en un Usuario, mostrara los repositorios de los que es dueño, de los que es colaborador, y los repositorios publicos de las organizaciones a las que pertenezca, asi como en los que participe. Si se ejecuta en el ambito de una Organizacion, mostrara todos los repositorios de una organizacion en concreto. Cuando ejecutamos el comando dentro de un Equipo, mostrara los repositorios que pertecen al mismo.

Si queremos realizar una busqueda inteligente, el comando permite el uso de *expresiones regulares*. Para ese caso deberia ejecutarse ``repos /<RegEx>/``

```sh
teams
```
Muestra todos los equipos de una organizacion.

```sh
new_team <nombre> <miembro1> <miembro2> ...
```
Crea un equipo a al que le sera asignado uno o varios miembros de la organizacion.

```sh
add_to_team <miembro1> <miembro2> ...
```
Dentro de un equipo en una organizacion, añadira nuevos miembros al equipo de trabajo.

```sh
groups
```
Muestra los grupos de equipos de una organizacion.

```sh
clone <nombre>
```
Clona el repositorio en el path actual. Es posible clonar una lista de repositorios usando una expresion regular. ``clone /<RegEx>/``

```sh
people
```
Muestra los miembros de una organizacion si nos encontramos en ese ambito, o los miembros de un equipo.

```sh
files <path>
```
Dentro de un repositorio, muestra los archivos y directorios que se encuentren en el path dado. Si se ejecuta sin opciones mostrara los archivos de la raiz del repositorio.

```sh
cat <file>
```
Muestra el contenido de un archivo.

```sh
commits
```
Muestra los commits del repositorio en el que se encuentre el usuario.






##Aditional information
[Github Education](https://education.github.com/)
