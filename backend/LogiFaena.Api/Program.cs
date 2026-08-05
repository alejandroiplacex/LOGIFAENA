using System.Text.Json;
using LogiFaena.Api.Data;
using LogiFaena.Api.Entities;
using Microsoft.EntityFrameworkCore;

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

    var receivedAtUtc = DateTime.UtcNow;

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
        ReceivedAtUtc = receivedAtUtc,
        Processed = false
    };

    dbContext.SyncOperations.Add(syncOperation);

    try
    {
        var entityType = request.EntityType
            .Trim()
            .ToLowerInvariant();

        var operation = request.Operation
            .Trim()
            .ToLowerInvariant();

        if (entityType != "worker")
        {
            syncOperation.ProcessingError =
                $"El tipo de entidad '{request.EntityType}' aún no está soportado.";

            await dbContext.SaveChangesAsync();

            return Results.BadRequest(new SyncResponse(
                Success: false,
                Message: syncOperation.ProcessingError,
                ReceivedAt: receivedAtUtc
            ));
        }

        var externalId = request.EntityId.Trim();

        var worker = await dbContext.Workers
            .SingleOrDefaultAsync(
                x => x.ExternalId == externalId
            );

        switch (operation)
        {
            case "create":
            case "update":
                if (worker is null)
                {
                    var highestWorkerId = await dbContext.Workers
                        .Select(x => (long?)x.Id)
                        .MaxAsync() ?? 0;

                    worker = new WorkerEntity
                    {
                        ExternalId = externalId,
                        WorkerCode =
                            $"LF-{highestWorkerId + 1:000000}",
                        QrToken = Guid.NewGuid().ToString("N"),
                        UpdatedAtUtc = receivedAtUtc,
                        IsDeleted = false
                    };

                    dbContext.Workers.Add(worker);
                }

                worker.Rut = ReadString(
                    request.Payload,
                    "rut",
                    worker.Rut
                );

                worker.FirstName = ReadString(
                    request.Payload,
                    "firstName",
                    worker.FirstName
                );

                worker.LastName = ReadString(
                    request.Payload,
                    "lastName",
                    worker.LastName
                );

                worker.Company = ReadString(
                    request.Payload,
                    "company",
                    worker.Company
                );

                worker.Role = ReadString(
                    request.Payload,
                    "role",
                    worker.Role
                );

                worker.Project = ReadString(
                    request.Payload,
                    "project",
                    worker.Project
                );

                worker.Shift = ReadString(
                    request.Payload,
                    "shift",
                    worker.Shift
                );

                worker.Supervisor = ReadString(
                    request.Payload,
                    "supervisor",
                    worker.Supervisor
                );

                worker.City = ReadString(
                    request.Payload,
                    "city",
                    worker.City
                );

                worker.Phone = ReadString(
                    request.Payload,
                    "phone",
                    worker.Phone
                );

                worker.Email = ReadString(
                    request.Payload,
                    "email",
                    worker.Email
                );

                worker.EmergencyContact = ReadString(
                    request.Payload,
                    "emergencyContact",
                    worker.EmergencyContact
                );

                worker.EmergencyPhone = ReadString(
                    request.Payload,
                    "emergencyPhone",
                    worker.EmergencyPhone
                );

                worker.Hotel = ReadString(
                    request.Payload,
                    "hotel",
                    worker.Hotel
                );

                worker.Room = ReadString(
                    request.Payload,
                    "room",
                    worker.Room
                );

                worker.Ticket = ReadString(
                    request.Payload,
                    "ticket",
                    worker.Ticket
                );

                worker.Transfer = ReadString(
                    request.Payload,
                    "transfer",
                    worker.Transfer
                );

                worker.Notes = ReadString(
                    request.Payload,
                    "notes",
                    worker.Notes
                );

                worker.Status = ReadString(
                    request.Payload,
                    "status",
                    worker.Status
                );

                worker.UpdatedAtUtc = receivedAtUtc;
                worker.IsDeleted = false;
                break;

            case "delete":
                if (worker is null)
                {
                    syncOperation.ProcessingError =
                        $"No existe el trabajador '{externalId}' para eliminar.";

                    await dbContext.SaveChangesAsync();

                    return Results.NotFound(new SyncResponse(
                        Success: false,
                        Message: syncOperation.ProcessingError,
                        ReceivedAt: receivedAtUtc
                    ));
                }

                worker.IsDeleted = true;
                worker.UpdatedAtUtc = receivedAtUtc;
                break;

            default:
                syncOperation.ProcessingError =
                    $"La operación '{request.Operation}' no está soportada.";

                await dbContext.SaveChangesAsync();

                return Results.BadRequest(new SyncResponse(
                    Success: false,
                    Message: syncOperation.ProcessingError,
                    ReceivedAt: receivedAtUtc
                ));
        }

        syncOperation.Processed = true;
        syncOperation.ProcessingError = null;

        await dbContext.SaveChangesAsync();

        return Results.Ok(new SyncResponse(
            Success: true,
            Message:
                "Sincronización procesada y almacenada correctamente.",
            ReceivedAt: receivedAtUtc
        ));
    }
    catch (Exception error)
    {
        syncOperation.Processed = false;
        syncOperation.ProcessingError = error.Message;

        try
        {
            await dbContext.SaveChangesAsync();
        }
        catch
        {
            // Conserva el error original si no puede actualizar la operación.
        }

        return Results.Problem(
            title: "Error al procesar la sincronización.",
            detail: error.Message,
            statusCode:
                StatusCodes.Status500InternalServerError
        );
    }
});

app.MapGet("/api/sync/operations", async (
    LogiFaenaDbContext dbContext) =>
{
    var operations = await dbContext.SyncOperations
        .AsNoTracking()
        .OrderByDescending(x => x.ReceivedAtUtc)
        .Take(100)
        .ToListAsync();

    return Results.Ok(operations);
});

app.MapGet("/api/workers", async (
    LogiFaenaDbContext dbContext) =>
{
    var workers = await dbContext.Workers
        .AsNoTracking()
        .Where(x => !x.IsDeleted)
        .OrderBy(x => x.LastName)
        .ThenBy(x => x.FirstName)
        .ToListAsync();

    return Results.Ok(workers);
});

app.MapGet("/api/workers/changes", async (
    DateTime? since,
    LogiFaenaDbContext dbContext) =>
{
    var sinceUtc =
        since?.ToUniversalTime() ?? DateTime.UnixEpoch;

    var workers = await dbContext.Workers
        .AsNoTracking()
        .Where(x => x.UpdatedAtUtc > sinceUtc)
        .OrderBy(x => x.UpdatedAtUtc)
        .ToListAsync();

    return Results.Ok(new WorkerChangesResponse(
        ServerTimeUtc: DateTime.UtcNow,
        Workers: workers
    ));
});

app.Run();

static string ReadString(
    JsonElement payload,
    string propertyName,
    string currentValue)
{
    if (payload.ValueKind != JsonValueKind.Object)
    {
        return currentValue;
    }

    if (!payload.TryGetProperty(
        propertyName,
        out var property))
    {
        return currentValue;
    }

    if (property.ValueKind == JsonValueKind.Null)
    {
        return string.Empty;
    }

    return property.ValueKind == JsonValueKind.String
        ? property.GetString() ?? string.Empty
        : property.ToString();
}

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

record WorkerChangesResponse(
    DateTime ServerTimeUtc,
    IReadOnlyList<WorkerEntity> Workers
);