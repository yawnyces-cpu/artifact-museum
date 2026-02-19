<?php
require_once __DIR__ . '/config.php';
setJsonHeaders();

session_name(SESSION_NAME);
session_set_cookie_params([
    'lifetime' => SESSION_LIFETIME,
    'path'     => '/',
    'httponly' => true,
    'samesite' => 'Strict',
]);
session_start();

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';
if (stripos($contentType, 'application/json') !== false) {
    $body = json_decode(file_get_contents('php://input'), true) ?? [];
} else {
    $body = $_POST;
}

$action = strtolower(trim($body['action'] ?? $_GET['action'] ?? 'check'));

if ($action === 'check') {
    if (!empty($_SESSION['admin_id'])) {
        jsonSuccess([
            'authenticated' => true,
            'username'      => $_SESSION['admin_username'] ?? '',
            'role'          => $_SESSION['admin_role']     ?? '',
        ]);
    } else {
        jsonResponse(401, ['success' => false, 'authenticated' => false]);
    }
}

if ($action === 'logout') {
    $_SESSION = [];
    session_destroy();
    jsonSuccess(['message' => 'Logged out successfully.']);
}

if ($action === 'login') {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        jsonError(405, 'Login requires POST.');
    }

    $username = trim($body['username'] ?? '');
    $password = $body['password']      ?? '';

    if ($username === '' || $password === '') {
        jsonError(400, 'Username and password are required.');
    }

    $attempts    = $_SESSION['login_attempts']    ?? 0;
    $lastAttempt = $_SESSION['login_last_attempt'] ?? 0;

    if ($attempts >= 5 && (time() - $lastAttempt) < 300) {
        $waitSecs = 300 - (time() - $lastAttempt);
        jsonError(429, "Too many failed attempts. Wait {$waitSecs} seconds.");
    }

    try {
        $pdo  = getPDO();
        $stmt = $pdo->prepare('SELECT * FROM ADMIN WHERE username = ? LIMIT 1');
        $stmt->execute([$username]);
        $admin = $stmt->fetch();

        if (!$admin || !password_verify($password, $admin['password_hash'])) {
            $_SESSION['login_attempts']     = $attempts + 1;
            $_SESSION['login_last_attempt'] = time();
            jsonError(401, 'Invalid credentials.');
        }

        session_regenerate_id(true);  
        $_SESSION['admin_id']       = $admin['admin_id'];
        $_SESSION['admin_username'] = $admin['username'];
        $_SESSION['admin_role']     = $admin['role'];

        unset($_SESSION['login_attempts'], $_SESSION['login_last_attempt']);

        if (password_needs_rehash($admin['password_hash'], PASSWORD_BCRYPT, ['cost' => BCRYPT_COST])) {
            $newHash = password_hash($password, PASSWORD_BCRYPT, ['cost' => BCRYPT_COST]);
            $pdo->prepare('UPDATE ADMIN SET password_hash = ? WHERE admin_id = ?')
                ->execute([$newHash, $admin['admin_id']]);
        }

        jsonSuccess([
            'message'  => 'Login successful.',
            'username' => $admin['username'],
            'role'     => $admin['role'],
        ]);

    } catch (PDOException $e) {
        jsonError(500, 'Server error during authentication.');
    }
}

jsonError(400, 'Unknown action. Use: login | logout | check');
