IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261113164346_InitialCreate'
)
BEGIN
    CREATE TABLE [WorkGroups] (
        [Id] int NOT NULL IDENTITY,
        [Code] varchar(64) NOT NULL,
        [Name] nvarchar(200) NOT NULL,
        [Description] nvarchar(500) NULL,
        [DisplayOrder] int NOT NULL,
        CONSTRAINT [PK_WorkGroups] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261113164346_InitialCreate'
)
BEGIN
    CREATE TABLE [WorkItems] (
        [Id] int NOT NULL IDENTITY,
        [GroupId] int NOT NULL,
        [Code] varchar(100) NOT NULL,
        [Title] nvarchar(300) NOT NULL,
        [ShortDescription] nvarchar(600) NOT NULL,
        [AcceptanceCriteria] nvarchar(max) NOT NULL,
        [StatusNote] nvarchar(300) NULL,
        [IsOpenDecision] bit NOT NULL DEFAULT CAST(0 AS bit),
        [DisplayOrder] int NOT NULL,
        [IsCompleted] bit NOT NULL DEFAULT CAST(0 AS bit),
        [CompletedAt] datetime2 NULL,
        [UpdatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_WorkItems] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_WorkItems_WorkGroups_GroupId] FOREIGN KEY ([GroupId]) REFERENCES [WorkGroups] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261113164346_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_WorkGroups_Code] ON [WorkGroups] ([Code]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261113164346_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_WorkItems_Code] ON [WorkItems] ([Code]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261113164346_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_WorkItems_GroupId_DisplayOrder] ON [WorkItems] ([GroupId], [DisplayOrder]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261113164346_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261113164346_InitialCreate', N'10.0.6');
END;

COMMIT;
GO

