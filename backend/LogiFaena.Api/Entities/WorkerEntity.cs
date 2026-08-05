namespace LogiFaena.Api.Entities;

public class WorkerEntity
{
    public long Id { get; set; }

    public string ExternalId { get; set; } = string.Empty;

    public string WorkerCode { get; set; } = string.Empty;

    public string QrToken { get; set; } = string.Empty;

    public string Rut { get; set; } = string.Empty;

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string Company { get; set; } = string.Empty;

    public string Role { get; set; } = string.Empty;

    public string Project { get; set; } = string.Empty;

    public string Shift { get; set; } = string.Empty;

    public string Supervisor { get; set; } = string.Empty;

    public string City { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string EmergencyContact { get; set; } = string.Empty;

    public string EmergencyPhone { get; set; } = string.Empty;

    public string Hotel { get; set; } = string.Empty;

    public string Room { get; set; } = string.Empty;

    public string Ticket { get; set; } = string.Empty;

    public string Transfer { get; set; } = string.Empty;

    public string Notes { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; }
}