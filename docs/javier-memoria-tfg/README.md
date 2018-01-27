# ghedsh memoria de TFG de Javier Clemente {#ghedsh-memoria-de-tfg-de-javier-clemente}

de de

GitHub Education Shell

**_Una Shell para el uso de GitHub en la Enseñanza_**

A Shell for the use of GitHub in Education

Javier Clemente Rodríguez Gómez

La Laguna, 5 de junio de 2017

Grado en Ingeniería Informática

Trabajo de Fin de Grado

![](export/assets/imagen1.jpg)![](export/assets/imagen9.jpg)

D. **Casiano Rodríguez León**, con N.I.F. 42.020.072-S profesor Catedrático de Universidad adscrito al Departamento de Ingeniería Informática y de Sistemas de la Universidad de La Laguna, como tutor

C E R T I F I C A (N)

Que la presente memoria titulada:

“GHEDSH: Una Shell para el uso de Github en la enseñanza”

ha sido realizada bajo su dirección por D. **Javier Clemente Rodríguez Gómez**,

con N.I.F. 78633504T.

Y para que así conste, en cumplimiento de la legislación vigente y a los efectos oportunos firman la presente en La Laguna a 5 de junio de 2017

Agradecimientos

Casiano Rodríguez León

Licencia

![](export/assets/imagen6.png)© Esta obra está bajo una licencia de Creative Commons Reconocimiento 4.0 Internacional.

Resumen

Este proyecto trata de la elaboración de un programa en Ruby que permita tanto el uso y manejo de datos de Github, como la asignación de tareas por medio de repositorios en el entorno educacional haciendo uso de una Shell. Para ello se seguirá la metodología de la plataforma GitHub Education sobre el manejo de las Organizaciones como una clase para profesor y sus alumnos.

**Palabras clave:** GitHub, GitHub Education, repositorios, organizaciones, asignaciones, Shell, Ruby

Abstract

This project is about the elaboration of a program in Ruby that allows both the use and handling of Github data, as well as the assignment of tasks through repositories in the educational environment using a Shell. This will be followed by the methodology of the GitHub Education platform on the management of Organizations as a class for teachers and their students.

**Keywords:** GitHub, GitHub Education, repositories, organizations, assignments, Shell, Ruby

Índice general

Índice general

Capítulo 1 Introducción1

1.1 ¿Que es GitHub Education?1

1.2 Antecedentes y situación actual2

Capítulo 2 Objetivos y plan de trabajo3

2.1 Objetivos3

2.2 Plan de trabajo4

Capítulo 3 Desarrollo de la aplicación5

3.1 Estudio sobre el funcionamiento de la API de GitHub5

3.1.1 Uso de la librería Octokit6

3.2 GitHub Education Shell7

3.2.1 Introducción y metodología7

3.2.2 Instalación 9

3.2.3 Autentificación11

3.2.4 Ejecutando el programa por primera vez13

3.3 Problemas encontrados y soluciones14

3.3.1 Consultas y datos recibidos por la API14

3.3.2 La usabilidad en la navegación14

Capítulo 4 Tutorial15

4.1 Navegación y uso básico15

4.2 Organizando la clase18

4.3 Manejando asignaciones23

Capítulo 5 Manual28

5.1 Comandos globales28

5.2 Comandos a nivel de Repositorio29

5.3 Comandos a nivel de Organización30

5.4 Comandos a nivel de Asignaciones33

5.5 Comandos a nivel de Equipo34

5.6 Comandos a nivel de Usuario35

Capítulo 6 Conclusiones y líneas futuras36

Capítulo 7 Summary and Conclusions37

Capítulo 8 Presupuesto38

8.1 Coste total38

8.2 Obtención de ingresos38

Capítulo 9 Bibliografía39

Índice de figuras

Índice de figuras

ghed1

ghclass2

diagrama7

oauth11

oauth212

oauth312

tutorial15

tutorial216

tutorial317

tutorial417

tutorial518

tutorial619

tutorial720

tutorial821

tutorial922

tutorial1023

tutorial1123

tutorial1224

tutorial1324

tutorial1424

tutorial1525

tutorial1625

tutorial1726

tutorial1826

tutorial1926

Índice de tablas

Índice de tablas

Plan de trabajo4