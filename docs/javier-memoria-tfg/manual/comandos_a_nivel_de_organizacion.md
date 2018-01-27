## Comandos a nivel de Organización {#comandos-a-nivel-de-organizaci-n}

assignmentsMuestra la lista de asignaciones.

cloneClona un repositorio.

clone [repositorio]

Puedes usar una expresión regular para clonar varios repositorios usando el parámetro “/”.

_clone /[RegExp]/_

groupMuestra la información de un grupo específico.

_group [nombre del grupo]_

groupsMuestra la lista de grupos y los equipos que pertenecen a ellos.

new assignmentCrea una nueva asignación en tu organización.

_new assignment [nombre de la asignacion_]

new groupCrear un nuevo grupo. Espera por parámetro el nombre y los grupos dados uno a uno.

_new group [nombre del grupo] [team1] [team2]_ [team3] ...

Si quieres importar los equipos desde un archivo, usa el parámetro “-f”.

_new group -f [name of the group] [file]_

new people infoRecoge la información extendida desde un archivo a .csv encontrado en el path de ejecución.

_new people info [nombre del fichero]_

new relationCrea una relación para la información extendida entre la ID de GitHub y un email desde un archivo .csv.

new relation [nombre del fichero]

new repositoryCrea un nuevo repositorio en la organización.

_new repository [nombre del repositorio]_

new teamCrea un nuevo equipo en la organización. Espera el nombre del equipo, y/o miembros dados uno por uno.

new team [nombre del equipo] [member1] [member2] [member3] ...

openAbre la URL de la organización de GitHub en tu navegador por defecto.

Si se ha añadido información adicional, se puede abrir la web del perfil de GitHub de un usuario pasándolo por parámetro.

_open [ID de GitHub]_

Se puede usar una expresión regular para abrir varios usuarios.

_open /RegExp/_

Puedes abrir un campo específico si este contiene una URL.

_open [user] [Nombre del campo]_

Si no se desea poner el campo, se puede hacer una búsqueda en los campos con parte de la URL que se quiera abrir.

_open [user] /[parte de la URL]/_

Cambien se puede usar una expresión regular para abrir varios usuarios a la vez con ese tipo de búsqueda.

_open /RegExp/ /[part of the URL]/_

peopleMuestra los miembros de la organización.

_people_

Si añades el parámetro “info”, se mostrara la información extendida.

_people info_

Para encontrar a alguien específico en la información extendida, puedes dar la ID de GitHub por parámetro.

_people info [github id]_

Puedes usar una expresión regular que buscaría por cada campo, usando el parámetro “/”.

_people info /[RegExp]/_

reposLista los repositorios de la organización.

Usa el parámetro “-a” para mostrar directamente la lista completa sin interrupciones.

_repos -a_

Puedes usar una expresión regular para mejorar la búsqueda usando el parámetro “/”

_repos /[RegExp]/_

rm groupBorra un grupo

_rm group [name of the group]_

rm people infoBorra la información extendida de una clase.

rm repositoryBorra un repositorio en la organización.

_rm repository [nombre del repositorio]_

rm teamBorra un equipo en la organización. Espera el nombre del equipo.

_rm team [nombre del equipo]_

teamsMuestra los equipos de la organización.