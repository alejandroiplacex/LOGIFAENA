using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapGet("/", () => Results.Ok(new
{
    application = "LogiFaena.Api",
    status = "online"
}));

app.MapPost("/api/sync", (SyncRequest request) =>
{
    if (string.IsNullOrWhiteSpace(request.Operation))
    {
        return Results.BadRequest(new SyncResponse(
            Success: false,
            Message: "La operación es obligatoria.",
            ReceivedAt: DateTime.UtcNow
        ));
    }

    if (string.IsNullOrWhiteSpace(request.EntityType))
    {
        return Results.BadRequest(new SyncResponse(
            Success: false,
            Message: "El tipo de entidad es obligatorio.",
            ReceivedAt: DateTime.UtcNow
        ));
    }

    return Results.Ok(new SyncResponse(
        Success: true,
        Message: "Sincronización recibida correctamente.",
        ReceivedAt: DateTime.UtcNow
    ));
});

app.Run();

record SyncRequest(
    int? Id,
    string EntityType,
    string EntityId,
    string Operation,
    JsonElement Payload,
    DateTime? CreatedAt,
    int Attempts,
    string Status
);

record SyncResponse(
    bool Success,
    string Message,
    DateTime ReceivedAt
);