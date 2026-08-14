namespace LogiFaena.Api.Entities;

public class MovementEntity
{
    public long Id { get; set; }

    public int? ClientMovementId { get; set; }

    public string WorkerId { get; set; } = string.Empty;

    public string WorkerCode { get; set; } = string.Empty;

    public string Type { get; set; } = string.Empty;

    public DateTime CreatedAtUtc { get; set; }

    public DateTime ReceivedAtUtc { get; set; }
}