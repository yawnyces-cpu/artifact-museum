-- ARTIFACT THESIS DATABASE (CLEAN VERSION)
-- 1. Disable checks to allow dropping tables safely
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- 2. NUCLEAR OPTION: Drop ALL possible variations of tables (Old & New)
DROP TABLE IF EXISTS `feedback`;
DROP TABLE IF EXISTS `painting_translations`; -- The "Zombie" table causing errors
DROP TABLE IF EXISTS `painting_info`;         -- The correct table
DROP TABLE IF EXISTS `paintings`;             -- Old plural name
DROP TABLE IF EXISTS `painting`;              -- New singular name
DROP TABLE IF EXISTS `languages`;             -- Old plural name
DROP TABLE IF EXISTS `language`;              -- New singular name
DROP TABLE IF EXISTS `admin`;

-- 3. REBUILD: Create Tables based STRICTLY on your ERD

-- Table: ADMIN
CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` varchar(20) DEFAULT 'admin',
  PRIMARY KEY (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `admin` (`username`, `password_hash`) VALUES
('admin', 'admin123');

-- Table: LANGUAGE
CREATE TABLE `language` (
  `language_id` int(11) NOT NULL AUTO_INCREMENT,
  `language_code` varchar(5) NOT NULL,
  `language_name` varchar(50) NOT NULL,
  PRIMARY KEY (`language_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `language` (`language_id`, `language_code`, `language_name`) VALUES
(1, 'en', 'English'),
(2, 'kr', 'Korean'),
(3, 'jp', 'Japanese'),
(4, 'cn', 'Chinese');

-- Table: PAINTING
CREATE TABLE `painting` (
  `painting_id` int(11) NOT NULL AUTO_INCREMENT,
  `qr_value` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `artist_name` varchar(255) DEFAULT NULL,
  `year_created` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`painting_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `painting` (`painting_id`, `qr_value`, `title`, `artist_name`, `year_created`) VALUES
(1, '0', 'The Spoliarium', 'Juan Luna', '1884'),
(2, '1', 'Mona Lisa', 'Leonardo da Vinci', '1503'),
(3, '2', 'The Starry Night', 'Vincent van Gogh', '1889');

-- Table: PAINTING_INFO
CREATE TABLE `painting_info` (
  `info_id` int(11) NOT NULL AUTO_INCREMENT,
  `painting_id` int(11) NOT NULL,
  `language_id` int(11) NOT NULL,
  `title_text` varchar(255) DEFAULT NULL,
  `rating` int(11) DEFAULT 5,
  `description_text` text DEFAULT NULL,
  `historical_background_text` text DEFAULT NULL,
  PRIMARY KEY (`info_id`),
  KEY `painting_id` (`painting_id`),
  KEY `language_id` (`language_id`),
  CONSTRAINT `fk_painting` FOREIGN KEY (`painting_id`) REFERENCES `painting` (`painting_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_language` FOREIGN KEY (`language_id`) REFERENCES `language` (`language_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `painting_info` (`painting_id`, `language_id`, `title_text`, `description_text`, `historical_background_text`) VALUES
(1, 1, 'The Spoliarium', 'A dramatic depiction of dying gladiators being dragged into the spoliarium.', 'Painted in Rome in 1884, winning the gold medal at the Exposición Nacional de Bellas Artes. It symbolizes the oppression of the Filipino people.'),
(2, 1, 'Mona Lisa', 'The woman with the mysterious smile, a masterpiece of the Renaissance.', 'Painted between 1503 and 1506. It was acquired by King Francis I of France and is now the property of the French Republic.'),
(3, 1, 'The Starry Night', 'A swirling night sky over a village, expressing emotion through color.', 'Painted in June 1889, it depicts the view from the east-facing window of his asylum room at Saint-Rémy-de-Provence.'),
(1, 2, '스폴리아리움', '스폴리아리움으로 끌려가는 죽어가는 검투사들의 극적인 묘사.', '1884년 로마에서 그려졌으며, 국립 미술 전시회에서 금메달을 수상했습니다.'),
(2, 2, '모나리자', '신비한 미소를 가진 여인, 르네상스의 걸작.', '1503년에서 1506년 사이에 그려졌습니다. 프랑스 국왕 프랑수아 1세가 구입했습니다.'),
(3, 2, '별이 빛나는 밤', '마을 위의 소용돌이치는 밤하늘, 색채를 통한 감정 표현.', '1889년 6월에 그려졌으며, 생레미드프로방스의 요양원 방 창문에서 본 풍경을 묘사합니다.'),
(1, 3, 'スポリアリウム', 'スポリアリウムに引きずり込まれる瀕死の剣闘士たちの劇的な描写。', '1884年にローマで描かれ、全国美術展で金メダルを獲得しました。'),
(2, 3, 'モナ・リザ', 'ルネサンスの傑作、神秘的な微笑みを浮かべた女性。', '1503年から1506年の間に描かれました。フランス王フランソワ1世によって取得されました。'),
(3, 3, '星月夜', '村の上に広がる渦巻く夜空、色による感情の表現。', '1889年6月に描かれ、サン＝レミ＝ド＝プロヴァンスの療養所の部屋からの眺めを描いています。'),
(1, 4, '斯波利亚里', '对垂死的角斗士被拖入斯波利亚里的戏剧性描绘。', '1884 年作于罗马，并在国家美术展览会上获得金奖。'),
(2, 4, '蒙娜丽莎', '带着神秘微笑的女人，文艺复兴时期的杰作。', '画于 1503 年至 1506 年之间。被法国国王弗朗索瓦一世收购。'),
(3, 4, '星夜', '村庄上空盘旋的夜空，通过色彩表达情感。', '画于 1889 年 6 月，描绘了他位于普罗旺斯圣雷米疗养院房间的窗外景色。');

-- Table: FEEDBACK
CREATE TABLE `feedback` (
  `feedback_id` int(11) NOT NULL AUTO_INCREMENT,
  `comment` text DEFAULT NULL,
  `feedback_time` timestamp NOT NULL DEFAULT current_timestamp(),
  `painting_id` int(11) DEFAULT NULL,
  `rating` int(11) DEFAULT NULL,
  PRIMARY KEY (`feedback_id`),
  KEY `painting_id` (`painting_id`),
  CONSTRAINT `fk_feedback_painting` FOREIGN KEY (`painting_id`) REFERENCES `painting` (`painting_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Re-enable checks
SET FOREIGN_KEY_CHECKS = 1;
COMMIT;