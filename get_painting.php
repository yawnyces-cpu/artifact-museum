<?php
// get_painting.php (Strict ERD Version)
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

include 'db_connect.php';

$id = isset($_GET['id']) ? intval($_GET['id']) : 1;

// 1. Get Core Data (From 'painting' table)
// Note: We use 'artist_name' and 'year_created' per your ERD
$sql_core = "SELECT * FROM painting WHERE painting_id = $id";
$result_core = $conn->query($sql_core);

if (!$result_core || $result_core->num_rows == 0) {
    echo json_encode(["error" => "Painting not found"]);
    exit();
}

$painting = $result_core->fetch_assoc();

// 2. Get Translations (From 'painting_info' joined with 'language')
// Note: We select 'historical_background_text' and 'description_text'
$sql_trans = "SELECT t.title_text, t.description_text, t.historical_background_text, l.language_code 
              FROM painting_info t
              JOIN language l ON t.language_id = l.language_id
              WHERE t.painting_id = $id";

$result_trans = $conn->query($sql_trans);

// 3. Construct the JSON Response
$response = [
    "painting_id" => $painting['painting_id'],
    "artist"      => $painting['artist_name'],  // Maps SQL 'artist_name' to JSON 'artist'
    "year"        => $painting['year_created'], // Maps SQL 'year_created' to JSON 'year'
    "title"       => $painting['title'],        // Default title
    "description" => "No description available.",
    "history"     => "No historical data available."
];

// 4. Loop through languages to fill data
while ($row = $result_trans->fetch_assoc()) {
    $code = $row['language_code']; // 'en', 'kr', 'jp', 'cn'
    
    if ($code == 'en') {
        $response['title'] = $row['title_text'];
        $response['description'] = $row['description_text'];
        $response['history'] = $row['historical_background_text'];
    } else {
        // Create dynamic keys like title_kr, desc_jp, hist_cn
        $response['title_' . $code] = $row['title_text'];
        $response['desc_' . $code] = $row['description_text'];
        $response['hist_' . $code] = $row['historical_background_text'];
    }
}

echo json_encode($response);
$conn->close();
?>