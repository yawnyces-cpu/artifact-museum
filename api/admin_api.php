<?php
require_once __DIR__ . '/config.php';
setJsonHeaders();

session_name(SESSION_NAME);
session_start();
if (empty($_SESSION['admin_id'])) {
    jsonError(401, 'Unauthorized. Please log in via admin_auth.php.');
}

$method   = $_SERVER['REQUEST_METHOD'];
$resource = strtolower(trim($_GET['resource'] ?? ''));

$body = [];
if ($method === 'POST') {
    $ct = $_SERVER['CONTENT_TYPE'] ?? '';
    $body = stripos($ct, 'application/json') !== false
        ? (json_decode(file_get_contents('php://input'), true) ?? [])
        : $_POST;
    $resource = strtolower(trim($body['resource'] ?? $resource));
}

$pdo = getPDO();

if ($resource === 'feedback') {

    if ($method === 'GET') {
        $paintingId = filter_var($_GET['painting_id'] ?? null, FILTER_VALIDATE_INT);
        $sql = '
            SELECT f.feedback_id, f.painting_id, p.title AS painting_title,
                   f.rating, f.comment, f.feedback_time
            FROM FEEDBACK f
            JOIN PAINTING p ON p.painting_id = f.painting_id
        ';
        $params = [];
        if ($paintingId) {
            $sql    .= ' WHERE f.painting_id = ?';
            $params[] = $paintingId;
        }
        $sql .= ' ORDER BY f.feedback_time DESC LIMIT 500';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        jsonSuccess(['feedback' => $stmt->fetchAll()]);
    }

    if ($method === 'POST' && ($body['action'] ?? '') === 'delete') {
        $id   = filter_var($body['feedback_id'] ?? null, FILTER_VALIDATE_INT);
        if (!$id) jsonError(400, 'Invalid feedback_id');
        $pdo->prepare('DELETE FROM FEEDBACK WHERE feedback_id = ?')->execute([$id]);
        jsonSuccess(['message' => 'Feedback deleted.']);
    }
}

if ($resource === 'paintings') {

    if ($method === 'GET') {
        $rows = $pdo->query('SELECT * FROM PAINTING ORDER BY painting_id ASC')->fetchAll();
        jsonSuccess(['paintings' => $rows]);
    }

    if ($method === 'POST') {
        $action = $body['action'] ?? '';

        if ($action === 'add') {
            $stmt = $pdo->prepare('
                INSERT INTO PAINTING (qr_value, title, artist_name, year_created)
                VALUES (:qr,:title,:artist,:year)
            ');
            $stmt->execute([
                ':qr'     => clean($body['qr_value']     ?? ''),
                ':title'  => clean($body['title']        ?? ''),
                ':artist' => clean($body['artist_name']  ?? ''),
                ':year'   => (int)($body['year_created'] ?? date('Y')),
            ]);
            jsonSuccess(['painting_id' => (int)$pdo->lastInsertId(), 'message' => 'Painting added.']);
        }

        if ($action === 'edit') {
            $id = filter_var($body['painting_id'] ?? null, FILTER_VALIDATE_INT);
            if (!$id) jsonError(400, 'Invalid painting_id');
            $stmt = $pdo->prepare('
                UPDATE PAINTING SET qr_value=:qr, title=:title, artist_name=:artist, year_created=:year
                WHERE painting_id=:id
            ');
            $stmt->execute([
                ':qr'     => clean($body['qr_value']     ?? ''),
                ':title'  => clean($body['title']        ?? ''),
                ':artist' => clean($body['artist_name']  ?? ''),
                ':year'   => (int)($body['year_created'] ?? date('Y')),
                ':id'     => $id,
            ]);
            jsonSuccess(['message' => 'Painting updated.']);
        }

        if ($action === 'delete') {
            $id = filter_var($body['painting_id'] ?? null, FILTER_VALIDATE_INT);
            if (!$id) jsonError(400, 'Invalid painting_id');
            $pdo->prepare('DELETE FROM PAINTING WHERE painting_id=?')->execute([$id]);
            jsonSuccess(['message' => 'Painting deleted.']);
        }
    }
}

if ($resource === 'painting_info') {

    if ($method === 'GET') {
        $pid  = filter_var($_GET['painting_id'] ?? null, FILTER_VALIDATE_INT);
        if (!$pid) jsonError(400, 'painting_id required');
        $stmt = $pdo->prepare('
            SELECT pi.*, l.language_code, l.language_name, l.flag_emoji
            FROM PAINTING_INFO pi JOIN LANGUAGE l ON l.language_id=pi.language_id
            WHERE pi.painting_id=?
        ');
        $stmt->execute([$pid]);
        jsonSuccess(['painting_info' => $stmt->fetchAll()]);
    }

    if ($method === 'POST') {
        $action = $body['action'] ?? '';

        if ($action === 'upsert') {
            $stmt = $pdo->prepare('
                INSERT INTO PAINTING_INFO
                    (painting_id, language_id, title_text, description_text, historical_background_text)
                VALUES (:pid,:lid,:title,:desc,:hist)
                ON DUPLICATE KEY UPDATE
                    title_text=VALUES(title_text),
                    description_text=VALUES(description_text),
                    historical_background_text=VALUES(historical_background_text)
            ');
            $stmt->execute([
                ':pid'   => (int)($body['painting_id']  ?? 0),
                ':lid'   => (int)($body['language_id']  ?? 0),
                ':title' => clean($body['title_text']   ?? ''),
                ':desc'  => $body['description_text']   ?? '',
                ':hist'  => $body['historical_background_text'] ?? '',
            ]);
            jsonSuccess(['message' => 'Painting info saved.']);
        }
    }
}

if ($resource === 'languages') {
    $rows = $pdo->query('SELECT * FROM LANGUAGE ORDER BY language_id')->fetchAll();
    jsonSuccess(['languages' => $rows]);
}

jsonError(400, 'Unknown resource. Use: feedback | paintings | painting_info | languages');
