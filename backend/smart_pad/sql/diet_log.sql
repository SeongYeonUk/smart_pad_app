USE smart_pad_db;

CREATE TABLE `diet_log` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `date` DATE NOT NULL,
    `meal_type` VARCHAR(255) NOT NULL,
    `main_dish` VARCHAR(255) NOT NULL,
    `sub_dish` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
);

DESCRIBE `diet_log`;