<?php

require_once __DIR__ . '/config.php';
setJsonHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    jsonError(405, 'Method not allowed. Use GET.');
}

$qrValue      = trim($_GET['qr_value']      ?? '');
$languageCode = strtoupper(trim($_GET['language_code'] ?? 'EN'));

if ($qrValue === '') {
    jsonError(400, 'Missing required parameter: qr_value');
}

$allowedLangs = ['EN', 'KR', 'JP', 'CH'];
if (!in_array($languageCode, $allowedLangs, true)) {
    jsonError(400, 'Invalid language_code. Allowed: EN, KR, JP, CH');
}

try {
    $pdo = getPDO();

    $sql = "
        SELECT
            p.painting_id,
            p.qr_value,
            p.title            AS painting_title,
            p.artist_name,
            p.year_created,

            /* Requested language — may be NULL if not yet translated */
            pi_req.title_text,
            pi_req.description_text,
            pi_req.historical_background_text,

            /* English fallback */
            pi_en.title_text                    AS title_text_en,
            pi_en.description_text              AS description_text_en,
            pi_en.historical_background_text    AS historical_background_text_en,

            l_req.language_name,
            l_req.flag_emoji
        FROM PAINTING p
        -- Join for requested language
        LEFT JOIN PAINTING_INFO pi_req
               ON pi_req.painting_id = p.painting_id
              AND pi_req.language_id  = (
                    SELECT language_id FROM LANGUAGE WHERE language_code = :lang_code1 LIMIT 1
                  )
        -- Join for English fallback
        LEFT JOIN PAINTING_INFO pi_en
               ON pi_en.painting_id  = p.painting_id
              AND pi_en.language_id  = (
                    SELECT language_id FROM LANGUAGE WHERE language_code = 'EN' LIMIT 1
                  )
        LEFT JOIN LANGUAGE l_req ON l_req.language_code = :lang_code2
        WHERE p.qr_value = :qr_value
        LIMIT 1
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':qr_value'   => $qrValue,
        ':lang_code1' => $languageCode,  
        ':lang_code2' => $languageCode,   
    ]);

    $row = $stmt->fetch();

    if (!$row) {
        jsonError(404, 'Painting not found for qr_value: ' . htmlspecialchars($qrValue));
    }

    $titleText      = $row['title_text']                    ?? $row['title_text_en']                    ?? $row['painting_title'];
    $descText       = $row['description_text']              ?? $row['description_text_en']              ?? '';
    $histBackground = $row['historical_background_text']    ?? $row['historical_background_text_en']    ?? '';

    $isFallback = ($row['title_text'] === null && $languageCode !== 'EN');

    jsonSuccess([
        'painting_id'                => (int) $row['painting_id'],
        'qr_value'                   => $row['qr_value'],
        'painting_title'             => $row['painting_title'], 
        'artist_name'                => $row['artist_name'],
        'year_created'               => (int) $row['year_created'],
        'language_code'              => $languageCode,
        'language_name'              => $row['language_name'] ?? 'English',
        'flag_emoji'                 => $row['flag_emoji']    ?? '🇬🇧',
        'title_text'                 => $titleText,
        'description_text'           => $descText,
        'historical_background_text' => $histBackground,
        'is_fallback_language'       => $isFallback,
    ]);

} catch (PDOException $e) {
    jsonError(500, 'Query error: ' . $e->getMessage());
}
