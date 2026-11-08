CREATE TABLE IF NOT EXISTS `qbx_materialbuyer_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `player_id` INT NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `player_name` VARCHAR(100) NOT NULL,
    `item_name` VARCHAR(100) NOT NULL,
    `item_label` VARCHAR(100) NOT NULL,
    `amount` INT UNSIGNED NOT NULL,
    `unit_price` INT UNSIGNED NOT NULL,
    `total_price` BIGINT UNSIGNED NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_created_at` (`created_at`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_item_name` (`item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
