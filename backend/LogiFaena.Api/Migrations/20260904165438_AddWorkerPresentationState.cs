using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace LogiFaena.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddWorkerPresentationState : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "PresentationAt",
                table: "Workers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PresentationNote",
                table: "Workers",
                type: "TEXT",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "PresentationStatus",
                table: "Workers",
                type: "TEXT",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PresentationAt",
                table: "Workers");

            migrationBuilder.DropColumn(
                name: "PresentationNote",
                table: "Workers");

            migrationBuilder.DropColumn(
                name: "PresentationStatus",
                table: "Workers");
        }
    }
}
