-- 사용할 데이터베이스를 지정합니다.
USE smart_pad_db;

-- patient_detail 테이블을 생성합니다.
CREATE TABLE `patient_detail` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL UNIQUE,
    `weight` DOUBLE NULL,
    `age_range` VARCHAR(255) NULL,
    `sensory_perception` VARCHAR(255) NULL,
    `activity_level` VARCHAR(255) NULL,
    `movement_level` VARCHAR(255) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`idusersusers`),
    FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE
);

-- 테이블이 잘 생성되었는지 확인합니다.
DESCRIBE `patient_detail`;users