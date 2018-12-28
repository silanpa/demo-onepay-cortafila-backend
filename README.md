# Proyecto de ejemplo Backend Cortafilas para Onepay

## Descripción

Este proyecto busca demostrar la integración de Onepay en modalidad Cortafilas, [descrita en la documentación oficial.](https://www.transbankdevelopers.cl/documentacion/onepay#integracion-cortafila)

La demostración consta de dos componentes:

- La [aplicación movil Android](https://github.com/continuum/transbank-demo-cortafilas-android-onepay) que muestra el código QR para pagar con Onepay
- La aplicación backend (este proyecto)


## Requisitos para ejecución en ambiente de desarrollo

- [Docker](https://www.docker.com)
- [Docker Compose](https://docs.docker.com/compose/install/)
- La [aplicación movil Android](https://github.com/continuum/transbank-demo-cortafilas-android-onepay) que consuma la API expuesta por el backend

## Instrucciones para ejecución

- Necesitas configurar las siguientes variables de entorno:
  - `API_KEY`, como parte de las credenciales de producción entregadas por Transbank
  - `SHARED_SECRET`, como parte de las credenciales de producción entregadas por Transbank
  - `BASE_DOMAIN`, dominio base en donde se ejecuta la aplicación
  - `FCM_TOKEN`, clave de servidor obtenido desde la consola de Firebase

Para obtener `FCM_TOKEN`, es necesario que te dirijas a la [Consola de Firebase](https://console.firebase.google.com), crear un proyecto, para luego ir a Project Overview y Configuración del Proyecto. Ve a `Mensajería en la nube`, y utiliza el token bajo el nombre `Clave del servidor`.

Luego, es necesario crear la base de datos:

- `docker-compose run --rm web rake db:create`

Correr las migraciones para que la base de datos esté preparada:

- `docker-compose run --rm web rake db:migrate`

¡Y listo! Puedes correr la aplicación ejecutando:

- `docker-compose run --rm --service-ports web`
