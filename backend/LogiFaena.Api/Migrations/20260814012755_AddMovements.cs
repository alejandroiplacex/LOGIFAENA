using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LogiFaena.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMovements : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Movements",
                columns: table => new
                {
                    Id = table.Column<long>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    ClientMovementId = table.Column<int>(type: "INTEGER", nullable: true),
                    WorkerId = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    WorkerCode = table.Column<string>(type: "TEXT", maxLength: 30, nullable: false),
                    Type = table.Column<string>(type: "TEXT", maxLength: 50, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ReceivedAtUtc = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Movements", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Movements_CreatedAtUtc",
                table: "Movements",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_Movements_WorkerCode",
                table: "Movements",
                column: "WorkerCode");

            migrationBuilder.CreateIndex(
                name: "IX_Movements_WorkerId",
                table: "Movements",
                column: "WorkerId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Movements");
        }
    }
}
