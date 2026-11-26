using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CafePosTracker.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "WorkGroups",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Code = table.Column<string>(type: "varchar(64)", unicode: false, maxLength: 64, nullable: false),
                    Name = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: true),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkGroups", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "WorkItems",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    GroupId = table.Column<int>(type: "int", nullable: false),
                    Code = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: false),
                    Title = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: false),
                    ShortDescription = table.Column<string>(type: "nvarchar(600)", maxLength: 600, nullable: false),
                    AcceptanceCriteria = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    StatusNote = table.Column<string>(type: "nvarchar(300)", maxLength: 300, nullable: true),
                    IsOpenDecision = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    DisplayOrder = table.Column<int>(type: "int", nullable: false),
                    IsCompleted = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    CompletedAt = table.Column<DateTime>(type: "datetime2", nullable: true),
                    UpdatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_WorkItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_WorkItems_WorkGroups_GroupId",
                        column: x => x.GroupId,
                        principalTable: "WorkGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_WorkGroups_Code",
                table: "WorkGroups",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WorkItems_Code",
                table: "WorkItems",
                column: "Code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_WorkItems_GroupId_DisplayOrder",
                table: "WorkItems",
                columns: new[] { "GroupId", "DisplayOrder" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "WorkItems");

            migrationBuilder.DropTable(
                name: "WorkGroups");
        }
    }
}
