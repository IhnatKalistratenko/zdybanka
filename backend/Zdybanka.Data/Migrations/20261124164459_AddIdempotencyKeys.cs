using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Zdybanka.Data.Migrations;

/// <inheritdoc />
public partial class AddIdempotencyKeys : Migration
{
    /// <inheritdoc />
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "IdempotencyKeys",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                Key = table.Column<string>(type: "text", nullable: false),
                ResponseBody = table.Column<string>(type: "text", nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
            },
            constraints: table => table.PrimaryKey("PK_IdempotencyKeys", row => row.Id));

        migrationBuilder.CreateIndex(
            name: "IX_IdempotencyKeys_Key",
            table: "IdempotencyKeys",
            column: "Key",
            unique: true);
    }

    /// <inheritdoc />
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "IdempotencyKeys");
    }
}
