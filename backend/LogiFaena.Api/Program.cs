using System.Text.Json;
using LogiFaena.Api.Data;
using Microsoft.EntityFrameworkCore;
using LogiFaena.Api.Entities;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<LogiFaenaDbContext>(options =>
    options.UseSqlite(
        builder.Configuration.GetConnectionString("LogiFaenaDatabase")
    )
);

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

app.MapPost("/api/sync", async (
    SyncRequest request,
    LogiFaenaDbContext dbContext) =>
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

    if (string.IsNullOrWhiteSpace(request.EntityId))
    {
        return Results.BadRequest(new SyncResponse(
            Success: false,
            Message: "El identificador de la entidad es obligatorio.",
            ReceivedAt: DateTime.UtcNow
        ));
    }

    var syncOperation = new SyncOperationEntity
    {
        ClientId = request.Id,
        EntityType = request.EntityType.Trim(),
        EntityId = request.EntityId.Trim(),
        Operation = request.Operation.Trim(),
        PayloadJson = request.Payload.GetRawText(),
        ClientCreatedAtUtc = request.CreatedAt,
        ClientAttempts = request.Attempts,
        ClientStatus = request.Status,
        ReceivedAtUtc = DateTime.UtcNow,
        Processed = false
    };

    dbContext.SyncOperations.Add(syncOperation);
    await dbContext.SaveChangesAsync();

    return Results.Ok(new SyncResponse(
        Success: true,
        Message: "Sincronización recibida y almacenada correctamente.",
        ReceivedAt: syncOperation.ReceivedAtUtc
    ));
    
});
app.MapGet("/api/sync/operations", async (
    LogiFaenaDbContext dbContext) =>
{
    var operations = await dbContext.SyncOperations
        .OrderByDescending(x => x.ReceivedAtUtc)
        .Take(100)
        .ToListAsync();

    return Results.Ok(operations);
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