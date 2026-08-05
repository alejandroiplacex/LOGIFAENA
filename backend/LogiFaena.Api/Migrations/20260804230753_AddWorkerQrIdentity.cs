using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LogiFaena.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkerQrIdentity : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "QrToken",
                table: "Workers",
                type: "TEXT",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "WorkerCode",
                table: "Workers",
                type: "TEXT",
                maxLength: 30,
                nullable: false,
                defaultValue: "");

            // Asigna un código visible único a cada trabajador existente.
            migrationBuilder.Sql(
                """
                UPDATE "Workers"
                SET "WorkerCode" = 'LF-' || printf('%06d', "Id")
                WHERE "WorkerCode" = '';
                """
            );

            // Asigna un token QR aleatorio a cada trabajador existente.
            migrationBuilder.Sql(
                """
                UPDATE "Workers"
                SET "QrToken" = lower(hex(randomblob(16)))
                WHERE "QrToken" = '';
                """
            );

            migrationBuilder.CreateIndex(
                name: "IX_Workers_QrToken",
                table: "Workers",
                column: "QrToken",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Workers_WorkerCode",
                table: "Workers",
                column: "WorkerCode",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Workers_QrToken",
                table: "Workers");

            migrationBuilder.DropIndex(
                name: "IX_Workers_WorkerCode",
                table: "Workers");

            migrationBuilder.DropColumn(
                name: "QrToken",
                table: "Workers");

            migrationBuilder.DropColumn(
                name: "WorkerCode",
                table: "Workers");
        }
    }
}