<?php
require_once __DIR__ . '/config.php';
setJsonHeaders();

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    jsonError(405, 'Method not allowed. Use POST.');
}

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
if (stripos($contentType, 'application/json') !== false) {
    $body = json_decode(file_get_contents('php://input'), true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        jsonError(400, 'Invalid JSON body.');
    }
} else {
    $body = $_POST;
}

$paintingId = filter_var($body['painting_id'] ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
$rating     = filter_var($body['rating']      ?? null, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1, 'max_range' => 5]]);
$comment    = trim($body['comment'] ?? '');

if ($paintingId === false || $paintingId === null) {
    jsonError(400, 'Invalid or missing painting_id (must be a positive integer).');
}
if ($rating === false || $rating === null) {
    jsonError(400, 'Invalid or missing rating (must be an integer 1–5).');
}

$comment = mb_substr(strip_tags($comment), 0, 2000); 

session_name(SESSION_NAME);
session_set_cookie_params(['lifetime' => SESSION_LIFETIME, 'samesite' => 'Lax']);
session_start();

$sessionKey = 'fb_' . $paintingId;
if (isset($_SESSION[$sessionKey])) {
    jsonError(429, 'You have already submitted feedback for this painting. Thank you!');
}

try {
    $pdo = getPDO();

    $checkStmt = $pdo->prepare('SELECT painting_id FROM PAINTING WHERE painting_id = ? LIMIT 1');
    $checkStmt->execute([$paintingId]);
    if (!$checkStmt->fetch()) {
        jsonError(404, 'Painting not found for painting_id: ' . $paintingId);
    }

    $insertSql = '
        INSERT INTO FEEDBACK (painting_id, rating, comment)
        VALUES (:painting_id, :rating, :comment)
    ';
    $insertStmt = $pdo->prepare($insertSql);
    $insertStmt->execute([
        ':painting_id' => $paintingId,
        ':rating'      => $rating,
        ':comment'     => $comment !== '' ? $comment : null,
    ]);

    $newFeedbackId = (int) $pdo->lastInsertId();

    $_SESSION[$sessionKey] = time();

    jsonSuccess([
        'feedback_id' => $newFeedbackId,
        'message'     => 'Thank you for your feedback!',
    ]);

} catch (PDOException $e) {
    jsonError(500, 'Database error: ' . $e->getMessage());
}
