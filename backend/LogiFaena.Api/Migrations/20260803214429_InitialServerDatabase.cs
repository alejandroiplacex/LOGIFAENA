using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LogiFaena.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialServerDatabase : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "SyncOperations",
                columns: table => new
                {
                    Id = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ClientId = table.Column<int>(type: "INTEGER", nullable: true),
                    EntityType = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    EntityId = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    Operation = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    PayloadJson = table.Column<string>(type: "TEXT", nullable: false),
                    ClientCreatedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: true),
                    ClientAttempts = table.Column<int>(type: "INTEGER", nullable: false),
                    ClientStatus = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    ReceivedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false),
                    Processed = table.Column<bool>(type: "INTEGER", nullable: false),
                    ProcessingError = table.Column<string>(type: "TEXT", maxLength: 2000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SyncOperations", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_SyncOperations_EntityType_EntityId_Operation_ClientCreatedAtUtc",
                table: "SyncOperations",
                columns: new[] { "EntityType", "EntityId", "Operation", "ClientCreatedAtUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "SyncOperations");
        }
    }
}
