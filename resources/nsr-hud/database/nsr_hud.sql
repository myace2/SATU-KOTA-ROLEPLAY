-- ============================================================================
-- NSR HUD ULTIMATE — DATABASE SCHEMA (database/nsr_hud.sql)
-- Compatible with MySQL 5.7+ / MariaDB 10.3+ and oxmysql
-- ============================================================================

CREATE TABLE IF NOT EXISTS `nsr_hud_profiles` (
    `identifier` VARCHAR(96) NOT NULL,
    `profile_json` LONGTEXT NOT NULL,
    `schema_version` INT NOT NULL DEFAULT 1,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`),
    INDEX `idx_nsr_hud_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
