# GITHUB EDUCATION SHELL

A command line program following the philosophy of GitHub Education.

## How does it work?

This program give you an interaction with Github like you was using your command line simulating a tree structure. Each level on the tree gives you several options of managing your Github account or your Organization.

Following the philosophy of Github Education, you can use this application to managing your own organization as a classroom where you can make assignments to your students using repository strategies.    

## Installing GHEDSH

You can download the gem **ghdesh** from rubygem.

``gem install ghdesh``

To run the app you need to call the binary file "ghedsh" in your command line after install it. Configuration files are being set in a hidden directory called *.ghedsh*, in your Home path.  

### First step: Oauth requirements.

Ir order to run this program, you need to make an **Access token** from Github with create and edit scope. When you run the program, it asks you the access token to identify yourself with no need to use your user and password.

[Link to create a new personal access token](https://github.com/settings/tokens/new?description=ghedsh)

You need to tick all options, unless admin:gpg_key scopes.  

### ghedsh executable options

'-t' or '--token token'. Provides a github access token by argument.

'-u', '--user user'. Change your user from your users list

'-v', '--version'. Show the current version of GHEDSH

'-h', '--help'. Displays Help

This program creates a directory called *.ghedsh* in your home with all configuration files that it needs.


## Basic usage
Logged in our app you start set in your personal profile. There you can list your repositories, create repositories, see your organizations and other options that you can see using the command *help* in your command line. You can go inside of a specific organization with the command *cd* and start to managing itself. Its possible to create task for the members your organization, create teamworks and many options that you can see again with *help*. You can move and go back in the tree directory as it is possible in the github structure.

```
Levels
└── User
    ├── Organizations
    │   ├── Groups
    │   ├── Teams
    │   │    └── Team Repositories
    │   ├── Assignments
    │   └── Organization Repositories
    └── User Repositories
```

## Lista de comandos


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
new team <nombre> <miembro1> <miembro2> ...
```
Crea un equipo a al que le sera asignado uno o varios miembros de la organizacion.

```sh
rm team <nombre> <miembro1> <miembro2> ...
```
Borra un equipo de una organizacion.

```sh
add to team <miembro1> <miembro2> ...
```

Dentro de un equipo en una organizacion, añadira nuevos miembros al equipo de trabajo.

```sh
new group <nombre> <equipo1> <equipo2> ...
```
Dentro de una organizacion, crea grupos donde asignar equipos de trabajo.

```sh
rm group <nombre> <equipo1> <equipo2> ...
```
Dentro de una organizacion, borra un grupo de trabajo.

```sh
groups
```
Muestra los grupos de equipos de una organizacion.

```sh
assignments
```
Muestra las tareas o asignaciones hechas para una organizacion.

```sh
new repository <nombre>
```
Crea un repositorio para un usuario, para una organizacion, o para un equipo dentro de una organizacion. Espera el nombre del repositorio.

```sh
rm repository <nombre>
```
Borra un repositorio de un usuario o de una organizacion. El comando espera el nombre del repositorio, ademas pedira confirmacion para el borrado del mismo si se ha comprobado su existencia.

```sh
clone <nombre>
```
Clona el repositorio en el path actual. Es posible clonar una lista de repositorios usando una expresion regular. ``clone /<RegEx>/``

```sh
people
```
Muestra los miembros de una organizacion si nos encontramos en ese ambito, o los miembros de un equipo.

```sh
people info
```
Muestra la informacion extendida de los miembros de la organizacion.

```sh
people info <usuario>
```
Muestra la informacion extendida de un miembro especifico de una organizacion.

```
user>organization> new relation file.csv
```
Esta orden provee un mecanismo para ampliar posteriormente 
la información sobre la gente/estudiantes (`people`) en la organización.
Establece una `relación` entre el nombre de usuario GitHub y un campo que servirá para la identificación
del usuario en la institución educativa.

En este ejemplo se establece el enlace entre la clave primaria de github (el nombre de usuario github)
y el email del alumno/profesor en la universidad:

```
crguezl>ULL-ESIT-GRADOII-TFG> new relation tfg-people.csv
```
El fichero `tfg-people.csv` contiene lo siguiente:
```
~/ghedsh(master)]$ cat tfg-people.csv 
"github","mail"
"alu0100505023","Clemente.ull.edu.es"
"alu0100769579","Raul.ull.edu.es"
"alu0100816167","Carlos.ull.edu.es"
"berkanrhdz","Berkan.ull.edu.es"
"Cicko","Rudolf.ull.edu.es"
"crguezl","Casiano.ull.edu.es"
"EleDiaz","Eleazar.ull.edu.es"
"jjlabrador","JJ.ull.edu.es"
"Losnen","Samuel.ull.edu.es"
"sokartema","Jazer.ull.edu.es"
```
Ahora podemos consultar de nuevo la información sobre los miembros:
```
crguezl>ULL-ESIT-GRADOII-TFG> people info /alu/

alu0100505023
Github:	 alu0100505023
Email:	 Clemente.ull.edu.es

...
```


```sh
new people info	<file>
```
Añade informacion extendida de los miembros de una organizacion mediante un archivo .csv.

Formato y campos de la informacion añadida: La primera linea del archivo .csv debera indicar el nombre de los campos que seran recogidos por el sistema.

```
 "github", "id", "nombre", "apellido", "emails", "organizaciones", "urls"
```

Ejemplo del contenido del archivo .csv. A partir de la primera linea de campos, cada nueva linea representara los datos de un alumno. Poniendo dobles comillas se podra añadir varios valores en un mismo campo.

```
 "studentbeta","alu1342","Pedro,Garcia Perez,""alu1342@ull.edu.es, pedrogarciaperez@gmail.com"",""classroom-testing, SYTW1617"",""http://campusvirtual.ull.es/aluXXX, http://pegarpe.github.io""
```

> "studentalpha1","alu321","Paco","Gutierrez","alu321@ull.edu.es","classroom-testing",","http://st.github.com"

Ejemplo:

```
crguezl>ULL-ESIT-GRADOII-TFG> new people info tfg-people-2

Fields found: 
"github"
"mail"
"nota"
```
El fichero `tfg-people-2.csv` contiene:
```
[~/TFGsrc/clementeTFG/ghedsh(master)]$ cat tfg-people-2.csv 
"github","mail","nota"
"alu0100505023","Clemente.ull.edu.es",4
"alu0100769579","Raul.ull.edu.es",6
"alu0100816167","Carlos.ull.edu.es",7
"berkanrhdz","Berkan.ull.edu.es",9
"Cicko","Rudolf.ull.edu.es",8
"crguezl","Casiano.ull.edu.es",5
"EleDiaz","Eleazar.ull.edu.es",6
"jjlabrador","JJ.ull.edu.es",9
"Losnen","Samuel.ull.edu.es",8
"sokartema","Jazer.ull.edu.es",9
```
Ahora podemos consultar la información añadida:
```
crguezl>ULL-ESIT-GRADOII-TFG> people info /alu.*6/

alu0100769579
Github:	 alu0100769579
Email:	 Raul.ull.edu.es
Nota:	 6


alu0100816167
Github:	 alu0100816167
Email:	 Carlos.ull.edu.es
Nota:	 7
```




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

```sh
private <true/false>
```
Modifica la privacidad de un repositorio estando situado dentro del mismo.

```sh
info
```
Dentro del repositorio, muestra informacion del mismo.

```sh
issues
```
Muestra los issues del repositorio en el que se encuentre el usuario.

```sh
issue <id>
```
Muestra un issue especifico, y permite ver ademas sus comentarios.

```sh
new issue comment <id>
```
Añade un comentario a un issue especifico.

```sh
new issue <nombre>
```
Crea un nuevo issue estando situado en un repositorio especifico. El titulo sera dado por parametro, y la descripcion sera introducida tras ejecutar el comando.

```sh
close issue <id>
```
Cierra un issue especifico dentro de un repositorio. Se debe especificar el issue mediante la id del mismo.

###Comandos para las Tareas o asignaciones

```sh
new assignment <nombre>
```
Crea una asignacion para una organizacion. Espera por parametro el nombre. Tras ejecutar el comando pedira un repositorio ya existente, la creacion de uno nuevo o la no insercion de un repositorio. Ademas esperara una lista de grupos para asignar a la tarea, ademas de la posible creacion de un grupo al que se le añadiran sus equipos. Todos los pasos pueden ser saltados, y tanto los grupos como el repositorio pueden ser añadidos posteriormente mediante **add_group** y **add_repo**.

```sh
cd <asignacion>
```
Dentro de una organizacion nos situara dentro de una asignacion para poder listar o editar los datos de la misma.

```sh
make <nombre>
```
Situado dentro de una asignacion o tarea, se creara un repositorio para cada equipo que pertenezca al grupo o grupos asignados. Se volcara el contenido del repositorio original a cada uno de los nuevos repositorios asignados a cada equipo.

```sh
info
```
Dentro de la asignacion, mostrara los datos de la misma. Se listaran los grupos y el repositorio asignado.

```sh
add_repo
```
Dentro de la asignacion, se activara el proceso de añadido del repositorio. Entre las opciones a elegir, estara la de añadir un repositorio ya creado, crear un nuevo repositorio o saltar el paso y no añadir el repositorio. Si ya habia un repositorio asignado anteriormente, este comando lo reemplazara.

```sh
add group
```
Dentro de la asignacion, se activara el proceso de añadido de groups. Entre las opciones a elegir, estaran la de añadir directamente grupos ya creados o crear uno desde cero. Si se crea uno desde cero se pedira un nombre o se creara un nombre con la fecha actual, despues se añadiran los equipos que perteneceran al grupo. Si ya existian grupos en la asignacion, este comando añadira otro mas a la lista.


## Aditional information

* [Github Education](https://education.github.com/)
* [Memoria de Trabajo Fin de Grado de Javier Clemente](https://github.com/ULL-ESIT-GRADOII-TFG/ghedsh/blob/master/docs/Javier-clemente-MemoriaTFG-ghedsh.pdf) (pdf en GitHub)
* [Memoria de Trabajo Fin de Grado de Javier Clemente](https://riull.ull.es/xmlui/handle/915/5117?show=full) (pdf en https://riull.ull.es)
* [Memoria de Trabajo Fin de Grado de Javier Clemente](http://ull-esit-gradoii-tfg.github.io/ghedsh/javier-memoria-tfg/_book/index.html) (html en GitHub, convertido automáticamente con GitBook)
* [Memoria de Trabajo Fin de Grado de Javier Clemente](https://github.com/ULL-ESIT-GRADOII-TFG/ghedsh/docs/javier-memoria-tfg/) (MarkDown en GitHub, convertido automáticamente)
