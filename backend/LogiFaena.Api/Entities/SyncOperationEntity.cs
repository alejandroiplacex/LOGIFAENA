namespace LogiFaena.Api.Entities;

public class SyncOperationEntity
{
    public long Id { get; set; }

    public int? ClientId { get; set; }

    public string EntityType { get; set; } = string.Empty;

    public string EntityId { get; set; } = string.Empty;

    public string Operation { get; set; } = string.Empty;

    public string PayloadJson { get; set; } = "{}";

    public DateTime? ClientCreatedAtUtc { get; set; }

    public int ClientAttempts { get; set; }

    public string ClientStatus { get; set; } = string.Empty;

    public DateTime ReceivedAtUtc { get; set; } = DateTime.UtcNow;

    public bool Processed { get; set; }

    public string? ProcessingError { get; set; }
}
