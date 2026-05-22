# Módulo 3: Servicio de Estadísticas - Acortador de URLs

Este repositorio contiene el código fuente y la infraestructura como código (IaC) para el **Módulo 3: Servicio de Estadísticas**, un componente analítico clave del proyecto integrador **Acortador de URLs con AWS + Terraform**.

## Objetivo del Módulo
El objetivo principal de este servicio es actuar como el proveedor de datos de analítica del sistema. Se encarga de procesar las peticiones de consulta de métricas, extraer la información histórica de interacciones desde Amazon DynamoDB y retornar un reporte estructurado con el total de clics y el desglose de visitas acumuladas por fecha.

### Características Clave:
* **Endpoint expuesto:** `GET /stats/{codigo}` a través de Amazon API Gateway.
* **Lógica Serverless:** AWS Lambda desarrollada en Node.js encargada de realizar la lectura analítica de la base de datos.
* **Consumo Eficiente:** Realiza consultas directas por llave primaria (`id`) para obtener los atributos `clicks` y el mapa `analytics` rellenado por el Módulo 2.
* **Soporte de Origen Cruzado (CORS):** Cabeceras HTTP configuradas nativamente para permitir el consumo seguro de las métricas desde el Dashboard del Módulo 4.

## Tecnologías Utilizadas
* **AWS Lambda:** Cómputo sin servidor para estructurar el JSON de respuesta analítica.
* **Amazon API Gateway:** Enrutamiento del método GET y exposición segura del endpoint para el consumo del Frontend.
* **Amazon DynamoDB:** Consulta de datos NoSQL sobre la tabla unificada del sistema.
* **Terraform:** Automatización completa del aprovisionamiento de la infraestructura (IaC).

## Estructura del Proyecto
```text
acortador-modulo3/
├── lambda/
│   └── index.js          # Código de la función Lambda (Lectura y formateo de estadísticas)
├── terraform/
│   ├── main.tf           # Declaración de recursos AWS (Lambda, API Gateway, IAM Roles)
│   ├── variables.tf      # Variables de entorno y configuración regional
│   └── outputs.tf        # Endpoint base exportado de la API de estadísticas
├── .gitignore            # Exclusión de estados de Terraform y archivos comprimidos .zip
└── README.md             # Documentación formal del módulo
Instrucciones de Despliegue Local
Prerrequisitos
AWS CLI configurado con credenciales de acceso vigentes (aws configure).

Terraform instalado localmente (versión v1.0.0 o superior).

Pasos para Desplegar:
Navega al directorio de infraestructura:

Bash
cd terraform
Inicializa el espacio de trabajo de Terraform:

Bash
terraform init
Verifica el plan de aprovisionamiento de recursos:

Bash
terraform plan
Despliega la infraestructura de manera automatizada:

Bash
terraform apply --auto-approve
Al finalizar, la consola de comandos mostrará en la sección de Outputs el enlace base del API Gateway. Este enlace deberá ser configurado en el Frontend de analítica para renderizar los gráficos del sistema.

Seguridad y Permisos (IAM)
Siguiendo las mejores prácticas de seguridad en la nube (Principio de Menor Privilegio), el rol de ejecución de esta función Lambda posee una política de IAM restringida que otorga permisos de solo lectura (dynamodb:GetItem) sobre la tabla de DynamoDB, además de los permisos requeridos para registrar trazas de ejecución en Amazon CloudWatch Logs.

Autoría
Desarrollador Responsable: [LEIWIS ANTONIO OSPINO ORTIZ/LEIWISO]
