CREATE DATABASE IF NOT EXISTS artifact_db
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE artifact_db;

CREATE TABLE IF NOT EXISTS ADMIN (
    admin_id      INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    username      VARCHAR(80)     NOT NULL UNIQUE,
    password_hash VARCHAR(255)    NOT NULL COMMENT 'bcrypt hash via password_hash()',
    role          ENUM('superadmin','editor') NOT NULL DEFAULT 'editor',
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (admin_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO ADMIN (username, password_hash, role) VALUES
('admin', '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'superadmin');

CREATE TABLE IF NOT EXISTS PAINTING (
    painting_id   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    qr_value      VARCHAR(255)    NOT NULL UNIQUE COMMENT 'Unique string encoded in the QR / used as MindAR target ID',
    title         VARCHAR(255)    NOT NULL,
    artist_name   VARCHAR(255)    NOT NULL,
    year_created  YEAR            NOT NULL,
    image_path    VARCHAR(512)    NULL     COMMENT 'Relative server path to the .mind target file',
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (painting_id),
    INDEX idx_qr_value (qr_value)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO PAINTING (qr_value, title, artist_name, year_created, image_path) VALUES
('ARTIFACT-PAINT-001', 'Spoliarium', 'Juan Luna', 1884, 'assets/targets/spoliarium.mind'),
('ARTIFACT-PAINT-002', 'The Parisian Life', 'Juan Luna', 1892, 'assets/targets/parisian_life.mind'),
('ARTIFACT-PAINT-003', 'Blood Compact', 'Juan Luna', 1886, 'assets/targets/blood_compact.mind');

CREATE TABLE IF NOT EXISTS LANGUAGE (
    language_id   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    language_code CHAR(5)         NOT NULL UNIQUE COMMENT 'ISO 639-1 or custom: EN, KR, JP, CH',
    language_name VARCHAR(60)     NOT NULL,
    flag_emoji    VARCHAR(10)     NULL,
    PRIMARY KEY (language_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO LANGUAGE (language_code, language_name, flag_emoji) VALUES
('EN', 'English',  '🇬🇧'),
('KR', 'Korean',   '🇰🇷'),
('JP', 'Japanese', '🇯🇵'),
('CH', 'Chinese',  '🇨🇳');

CREATE TABLE IF NOT EXISTS PAINTING_INFO (
    info_id                  INT UNSIGNED NOT NULL AUTO_INCREMENT,
    painting_id              INT UNSIGNED NOT NULL,
    language_id              INT UNSIGNED NOT NULL,
    title_text               VARCHAR(255) NOT NULL COMMENT 'Localised title',
    description_text         TEXT         NOT NULL COMMENT 'Short display description',
    historical_background_text TEXT       NOT NULL COMMENT 'Full historical content shown in modal',
    PRIMARY KEY (info_id),
    UNIQUE KEY uq_painting_language (painting_id, language_id),
    CONSTRAINT fk_pi_painting  FOREIGN KEY (painting_id)  REFERENCES PAINTING(painting_id)  ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pi_language  FOREIGN KEY (language_id)  REFERENCES LANGUAGE(language_id)  ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO PAINTING_INFO (painting_id, language_id, title_text, description_text, historical_background_text) VALUES
(1, 1, 'Spoliarium',
 'A monumental oil-on-canvas depicting the brutal aftermath of Roman gladiatorial combat.',
 'The Spoliarium is a large-scale painting by Filipino artist Juan Luna completed in 1884. It depicts the Roman spoliarium — the room adjacent to the Colosseum where the dead and dying gladiators were stripped of their armour. Luna submitted the work to the Exposición Nacional de Bellas Artes in Madrid, where it won the first gold medal. Rizal, who witnessed the unveiling, declared it a metaphor for the colonial condition of the Filipino people — their rights, aspirations, and very lives stripped from them much like the armour of the fallen gladiators. The painting measures 4.22 m × 7.675 m and is housed permanently in the National Museum of Fine Arts in Manila.'),
(1, 2, '스폴리아리움',
 '로마 검투사 경기의 잔혹한 여파를 묘사한 거대한 유화 작품.',
 '스폴리아리움은 필리핀 예술가 후안 루나가 1884년에 완성한 대형 회화입니다. 이 작품은 죽거나 다친 검투사들의 갑옷을 벗기던 로마 콜로세움 옆의 방 — 스폴리아리움 — 을 묘사합니다. 루나는 이 작품을 마드리드 국립미술 박람회에 출품하여 1등 금메달을 수상했습니다. 리살은 이 그림이 식민지 필리핀인들의 상황을 은유한다고 선언했습니다.'),
(1, 3, 'スポリアリウム',
 'ローマの剣闘士競技の残酷な aftermath を描いた大型油彩画。',
 'スポリアリウムは、フィリピンの画家フアン・ルナが1884年に完成させた大型絵画です。死傷した剣闘士の鎧を剥ぎ取るローマのコロッセオ隣の部屋（スポリアリウム）を描いています。ルナはこの作品をマドリードの国立美術博覧会に出品し、第一位の金メダルを受賞しました。'),
(1, 4, '斗兽场死室',
 '描绘罗马角斗士竞技残酷余波的大型油画。',
 '《斗兽场死室》是菲律宾画家胡安·卢纳于1884年完成的大型油画。画作描绘了罗马竞技场旁边的斗兽场死室——剥夺受伤和死亡角斗士铠甲的房间。卢纳将此作品提交给马德里国立美术博览会，荣获一等金奖。黎萨尔认为这幅画是菲律宾人民在殖民统治下处境的隐喻。');

CREATE TABLE IF NOT EXISTS FEEDBACK (
    feedback_id   INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    painting_id   INT UNSIGNED    NOT NULL,
    rating        TINYINT UNSIGNED NOT NULL COMMENT '1 to 5 stars',
    comment       TEXT            NULL,
    feedback_time TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (feedback_id),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_fb_painting FOREIGN KEY (painting_id) REFERENCES PAINTING(painting_id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_feedback_painting (painting_id),
    INDEX idx_feedback_time     (feedback_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE OR REPLACE VIEW vw_feedback_summary AS
    SELECT
        p.painting_id,
        p.title                        AS painting_title,
        COUNT(f.feedback_id)           AS total_responses,
        ROUND(AVG(f.rating), 2)        AS average_rating,
        SUM(CASE WHEN f.rating = 5 THEN 1 ELSE 0 END) AS five_star,
        SUM(CASE WHEN f.rating = 4 THEN 1 ELSE 0 END) AS four_star,
        SUM(CASE WHEN f.rating = 3 THEN 1 ELSE 0 END) AS three_star,
        SUM(CASE WHEN f.rating = 2 THEN 1 ELSE 0 END) AS two_star,
        SUM(CASE WHEN f.rating = 1 THEN 1 ELSE 0 END) AS one_star
    FROM PAINTING p
    LEFT JOIN FEEDBACK f ON p.painting_id = f.painting_id
    GROUP BY p.painting_id, p.title;
