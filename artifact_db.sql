-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 18, 2026 at 01:50 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `artifact_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` varchar(20) DEFAULT 'admin'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`admin_id`, `username`, `password_hash`, `role`) VALUES
(1, 'admin', 'admin123', 'admin');

-- --------------------------------------------------------

--
-- Table structure for table `feedback`
--

CREATE TABLE `feedback` (
  `feedback_id` int(11) NOT NULL,
  `painting_id` int(11) NOT NULL,
  `rating` int(11) DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `feedback_time` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `feedback`
--

INSERT INTO `feedback` (`feedback_id`, `painting_id`, `rating`, `comment`, `feedback_time`) VALUES
(1, 1, 0, 'NON', '2026-02-18 12:41:37'),
(2, 1, 5, 'cinema', '2026-02-18 12:42:17');

-- --------------------------------------------------------

--
-- Table structure for table `language`
--

CREATE TABLE `language` (
  `language_id` int(11) NOT NULL,
  `language_code` varchar(5) NOT NULL,
  `language_name` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `language`
--

INSERT INTO `language` (`language_id`, `language_code`, `language_name`) VALUES
(1, 'en', 'English'),
(2, 'kr', 'Korean'),
(3, 'jp', 'Japanese'),
(4, 'cn', 'Chinese');

-- --------------------------------------------------------

--
-- Table structure for table `painting`
--

CREATE TABLE `painting` (
  `painting_id` int(11) NOT NULL,
  `qr_value` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `artist_name` varchar(255) DEFAULT NULL,
  `year_created` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `painting`
--

INSERT INTO `painting` (`painting_id`, `qr_value`, `title`, `artist_name`, `year_created`) VALUES
(1, '0', 'The Spoliarium', 'Juan Luna', '1884'),
(2, '1', 'Mona Lisa', 'Leonardo da Vinci', '1503'),
(3, '2', 'The Starry Night', 'Vincent van Gogh', '1889');

-- --------------------------------------------------------

--
-- Table structure for table `painting_info`
--

CREATE TABLE `painting_info` (
  `info_id` int(11) NOT NULL,
  `painting_id` int(11) NOT NULL,
  `language_id` int(11) NOT NULL,
  `title_text` varchar(255) DEFAULT NULL,
  `rating` int(11) DEFAULT 5,
  `description_text` text DEFAULT NULL,
  `historical_background_text` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `painting_info`
--

INSERT INTO `painting_info` (`info_id`, `painting_id`, `language_id`, `title_text`, `rating`, `description_text`, `historical_background_text`) VALUES
(1, 1, 1, 'The Spoliarium', 5, 'A dramatic depiction of dying gladiators being dragged into the spoliarium.', 'Painted in Rome in 1884, winning the gold medal at the Exposición Nacional de Bellas Artes. It symbolizes the oppression of the Filipino people.'),
(2, 2, 1, 'Mona Lisa', 5, 'The woman with the mysterious smile, a masterpiece of the Renaissance.', 'Painted between 1503 and 1506. It was acquired by King Francis I of France and is now the property of the French Republic.'),
(3, 3, 1, 'The Starry Night', 5, 'A swirling night sky over a village, expressing emotion through color.', 'Painted in June 1889, it depicts the view from the east-facing window of his asylum room at Saint-Rémy-de-Provence.'),
(4, 1, 2, '스폴리아리움', 5, '스폴리아리움으로 끌려가는 죽어가는 검투사들의 극적인 묘사.', '1884년 로마에서 그려졌으며, 국립 미술 전시회에서 금메달을 수상했습니다.'),
(5, 2, 2, '모나리자', 5, '신비한 미소를 가진 여인, 르네상스의 걸작.', '1503년에서 1506년 사이에 그려졌습니다. 프랑스 국왕 프랑수아 1세가 구입했습니다.'),
(6, 3, 2, '별이 빛나는 밤', 5, '마을 위의 소용돌이치는 밤하늘, 색채를 통한 감정 표현.', '1889년 6월에 그려졌으며, 생레미드프로방스의 요양원 방 창문에서 본 풍경을 묘사합니다.'),
(7, 1, 3, 'スポリアリウム', 5, 'スポリアリウムに引きずり込まれる瀕死の剣闘士たちの劇的な描写。', '1884年にローマで描かれ、全国美術展で金メダルを獲得しました。'),
(8, 2, 3, 'モナ・リザ', 5, 'ルネサンスの傑作、神秘的な微笑みを浮かべた女性。', '1503年から1506年の間に描かれました。フランス王フランソワ1世によって取得されました。'),
(9, 3, 3, '星月夜', 5, '村の上に広がる渦巻く夜空、色による感情の表現。', '1889年6月に描かれ、サン＝レミ＝ド＝プロヴァンスの療養所の部屋からの眺めを描いています。'),
(10, 1, 4, '斯波利亚里', 5, '对垂死的角斗士被拖入斯波利亚里的戏剧性描绘。', '1884 年作于罗马，并在国家美术展览会上获得金奖。'),
(11, 2, 4, '蒙娜丽莎', 5, '带着神秘微笑的女人，文艺复兴时期的杰作。', '画于 1503 年至 1506 年之间。被法国国王弗朗索瓦一世收购。'),
(12, 3, 4, '星夜', 5, '村庄上空盘旋的夜空，通过色彩表达情感。', '画于 1889 年 6 月，描绘了他位于普罗旺斯圣雷米疗养院房间的窗外景色。');

-- --------------------------------------------------------

--
-- Table structure for table `painting_translations`
--

CREATE TABLE `painting_translations` (
  `trans_id` int(11) NOT NULL,
  `painting_id` int(11) NOT NULL,
  `lang_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `painting_translations`
--

INSERT INTO `painting_translations` (`trans_id`, `painting_id`, `lang_id`, `title`, `description`) VALUES
(1, 1, 1, 'The Spoliarium', 'A dramatic depiction of dying gladiators.'),
(2, 2, 1, 'Mona Lisa', 'The woman with the mysterious smile.'),
(3, 3, 1, 'Starry Night', 'A swirling night sky over a village.'),
(4, 1, 2, '스폴리아리움', '죽어가는 검투사들의 극적인 묘사.'),
(5, 2, 2, '모나리자', '신비한 미소를 가진 여인.'),
(6, 3, 2, '별이 빛나는 밤', '마을 위의 소용돌이치는 밤하늘.'),
(7, 1, 3, 'スポリアリウム', 'スポリアリウムに引きずり込まれる瀕死の剣闘士たちの劇的な描写。'),
(8, 2, 3, 'モナ・リザ', 'イタリア・ルネサンスの典型的な傑作とされる半身像。'),
(9, 3, 3, '星月夜', '精神病院の部屋の東向きの窓からの眺めを描いた油彩画。'),
(10, 1, 4, '斯波利亚里', '对垂死的角斗士被拖入斯波利亚里的戏剧性描绘。'),
(11, 2, 4, '蒙娜丽莎', '被认为是意大利文艺复兴时期典型的杰作的半身肖像画。'),
(12, 3, 4, '星夜', '一幅描绘了他精神病院房间朝东窗户景色的布面油画。');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`admin_id`);

--
-- Indexes for table `feedback`
--
ALTER TABLE `feedback`
  ADD PRIMARY KEY (`feedback_id`),
  ADD KEY `painting_id` (`painting_id`);

--
-- Indexes for table `language`
--
ALTER TABLE `language`
  ADD PRIMARY KEY (`language_id`);

--
-- Indexes for table `painting`
--
ALTER TABLE `painting`
  ADD PRIMARY KEY (`painting_id`);

--
-- Indexes for table `painting_info`
--
ALTER TABLE `painting_info`
  ADD PRIMARY KEY (`info_id`),
  ADD KEY `painting_id` (`painting_id`),
  ADD KEY `language_id` (`language_id`);

--
-- Indexes for table `painting_translations`
--
ALTER TABLE `painting_translations`
  ADD PRIMARY KEY (`trans_id`),
  ADD KEY `painting_id` (`painting_id`),
  ADD KEY `lang_id` (`lang_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `feedback`
--
ALTER TABLE `feedback`
  MODIFY `feedback_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `language`
--
ALTER TABLE `language`
  MODIFY `language_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `painting`
--
ALTER TABLE `painting`
  MODIFY `painting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `painting_info`
--
ALTER TABLE `painting_info`
  MODIFY `info_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `painting_translations`
--
ALTER TABLE `painting_translations`
  MODIFY `trans_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `feedback`
--
ALTER TABLE `feedback`
  ADD CONSTRAINT `feedback_ibfk_1` FOREIGN KEY (`painting_id`) REFERENCES `painting` (`painting_id`) ON DELETE CASCADE;

--
-- Constraints for table `painting_info`
--
ALTER TABLE `painting_info`
  ADD CONSTRAINT `painting_info_ibfk_1` FOREIGN KEY (`painting_id`) REFERENCES `painting` (`painting_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `painting_info_ibfk_2` FOREIGN KEY (`language_id`) REFERENCES `language` (`language_id`) ON DELETE CASCADE;

--
-- Constraints for table `painting_translations`
--
ALTER TABLE `painting_translations`
  ADD CONSTRAINT `painting_translations_ibfk_1` FOREIGN KEY (`painting_id`) REFERENCES `paintings` (`painting_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `painting_translations_ibfk_2` FOREIGN KEY (`lang_id`) REFERENCES `languages` (`lang_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
