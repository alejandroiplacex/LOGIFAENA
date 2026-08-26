using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LogiFaena.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkerOperationalLocation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "OperationalLocation",
                table: "Workers",
                type: "TEXT",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "OperationalLocationAt",
                table: "Workers",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "OperationalLocation",
                table: "Workers");

            migrationBuilder.DropColumn(
                name: "OperationalLocationAt",
                table: "Workers");
        }
    }
}
