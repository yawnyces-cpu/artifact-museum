<?php
// db_connect.php
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "artifact_db"; // Ensure this matches your phpMyAdmin database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set charset to utf8mb4 to handle Korean/Chinese/Japanese characters correctly
$conn->set_charset("utf8mb4");
?>