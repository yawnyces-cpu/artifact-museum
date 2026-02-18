<?php
// submit_feedback.php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

include 'db_connect.php';

$inputJSON = file_get_contents('php://input');
$input = json_decode($inputJSON, true);

if (!isset($input['painting_id']) || !isset($input['rating'])) {
    echo json_encode(["status" => "error", "message" => "Missing data"]);
    exit();
}

$painting_id = intval($input['painting_id']);
$rating = intval($input['rating']);
$comment = isset($input['comment']) ? $conn->real_escape_string($input['comment']) : "";

// Insert into 'feedback' table
// Note: We include 'rating' per Class Diagram/ERD alignment
$sql = "INSERT INTO feedback (painting_id, rating, comment) VALUES ('$painting_id', '$rating', '$comment')";

if ($conn->query($sql) === TRUE) {
    echo json_encode(["status" => "success", "message" => "Thank you! Feedback saved."]);
} else {
    echo json_encode(["status" => "error", "message" => "Error: " . $conn->error]);
}

$conn->close();
?>