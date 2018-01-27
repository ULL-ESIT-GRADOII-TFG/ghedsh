## Problemas encontrados y soluciones {#problemas-encontrados-y-soluciones}

### Consultas y datos recibidos por la API {#consultas-y-datos-recibidos-por-la-api}

1.  1.  1.  

La ejecución de las consultas a veces mostraba cierta inconsistencia a la hora de devolver los resultados, sobretodo cuando no se encontraban datos que retornar. Por lo que era posible que en consultas similares se enviaran datos “vacíos”, o la API retornara fallo y por consecuencia parase la ejecución del programa.

Esto hizo que tuviese que hacer uso del manejo excepciones en cada consulta que no retornase datos, a base de probar y decidir que consulta necesitaba especial atención.

### La usabilidad en la navegación {#la-usabilidad-en-la-navegaci-n}

Las primeras versiones si bien siendo funcionales, demostraban que el manejo de la aplicación no era del todo cómodo para el usuario. Al tener a veces tantos datos que manejar, y tantas utilidades que usar en diferentes ámbitos, hacia que de primeras no fuese tan accesible al usuario la navegación y uso de GHEDSH.

Para mejorar esta situación se tomaron varias medidas. Se añadieron opciones de autocompletar de tanto los comandos como los datos volcados desde la API, se creó un historial no solo para la sesión actual sino también funcional cuando se volviese a ejecutar el programa, el guardado de la posición del último nivel al regresar a la aplicación, la creación de varios perfiles de usuario poder usar el programa en varias cuentas, etc.

Todas estas medidas han hecho más natural y cómoda la navegación, mejorando la usabilidad y eliminando el problema encontrado.