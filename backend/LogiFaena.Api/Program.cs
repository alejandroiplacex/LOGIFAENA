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
    var sinceUtc = since?.ToUniversalTime() ?? DateTime.UnixEpoch;

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

    if (!payload.TryGetProperty(propertyName, out var property))
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