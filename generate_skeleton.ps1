# generate_skeleton.ps1
# Lệnh này chỉ lấy CẤU TRÚC (Function headers, Types, Services) bỏ qua nội dung code.

$outputFile = "PROJECT_SKELETON.txt"
$srcFolder = ".\src"

"--- ROBLOX PROJECT ARCHITECTURE (SKELETON) ---" | Out-File $outputFile -Encoding utf8

Get-ChildItem -Path $srcFolder -Recurse -Include *.luau, *.lua | ForEach-Object {
    $relativePath = $_.FullName.Replace($PWD.Path, "")
    
    "`n----------------------------------------" | Out-File $outputFile -Append -Encoding utf8
    "FILE: $relativePath" | Out-File $outputFile -Append -Encoding utf8
    "----------------------------------------" | Out-File $outputFile -Append -Encoding utf8

    # Chỉ lấy các dòng quan trọng: export type, function, requires, services
    Get-Content $_.FullName | Where-Object { 
        $_ -match "^\s*export type" -or 
        $_ -match "^\s*function" -or 
        $_ -match "^\s*local function" -or 
        $_ -match "^\s*local.*require" -or
        $_ -match "^\s*return" 
    } | Out-File $outputFile -Append -Encoding utf8
}

Write-Host "Skeleton generated! Size is optimized."