const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, GetCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.DYNAMODB_TABLE || "ShortUrlsTable";

exports.handler = async (event) => {
    console.log("Evento recibido:", JSON.stringify(event));

    try {
        // Capturar el código desde los parámetros de la ruta
        const shortCode = event.pathParameters ? event.pathParameters.codigo : null;
        // Capturar la fecha opcional si viene como Query String Parameter (?fecha=YYYY-MM-DD)
        const filterDate = event.queryStringParameters ? event.queryStringParameters.fecha : null;

        if (!shortCode) {
            return {
                statusCode: 400,
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ error: "El código corto es requerido en la ruta." })
            };
        }

        // Obtener el registro desde DynamoDB
        const result = await docClient.send(new GetCommand({
            TableName: TABLE_NAME,
            Key: { id: shortCode }
        }));

        if (!result.Item) {
            return {
                statusCode: 404,
                headers: { 
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                },
                body: JSON.stringify({ error: "No se encontraron estadísticas para el código proporcionado." })
            };
        }

        const { clicks, analytics, long_url, created_at } = result.Item;

        // Si el usuario envió una fecha para filtrar
        if (filterDate) {
            const clicksOnDate = analytics[filterDate] || 0;
            return {
                statusCode: 200,
                headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
                body: JSON.stringify({
                    short_code: shortCode,
                    long_url: long_url,
                    filter_date: filterDate,
                    clicks_on_date: clicksOnDate
                })
            };
        }

        // Si no se envía filtro, devolver el consolidado general requerido por la guía
        return {
            statusCode: 200,
            headers: { 
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*" 
            },
            body: JSON.stringify({
                short_code: shortCode,
                long_url: long_url,
                created_at: created_at,
                total_clicks: clicks,
                clicks_by_day: analytics
            })
        };

    } catch (error) {
        console.error("Error al obtener estadísticas:", error);
        return {
            statusCode: 500,
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ error: "Error interno al procesar las estadísticas." })
        };
    }
};