# © 2025 My-TS.org. All rights reserved.
# TeamSpeak Query Account Creator - for www.My-TS.org
# This script creates a limited permission group that you can assign to a specific user on your teamspeak server.
# You can then create a query login with that user to use on my-ts.org as query login.

param (
    [Parameter(Mandatory=$true)][string]$ServerIP,
    [Parameter(Mandatory=$true)][int]$QueryPort,
    [Parameter(Mandatory=$true)][string]$AdminUser,
    [Parameter(Mandatory=$true)][string]$AdminPass
)

function Send-TSCommand {
    param (
        [string]$Command,
        [System.Net.Sockets.TcpClient]$tcpClient,
        [System.IO.StreamReader]$reader,
        [System.IO.StreamWriter]$writer
    )
    
    try {
        Write-Host "Sending command: $Command" -ForegroundColor Cyan
        
        # Send command
        $writer.WriteLine($Command)
        $writer.Flush()
        
        # Read response with timeout
        $response = New-Object System.Text.StringBuilder
        $startTime = Get-Date
        $timeoutSeconds = 10
        
        while ((Get-Date) -lt $startTime.AddSeconds($timeoutSeconds)) {
            if ($reader.Peek() -eq -1) {
                # No data available, wait a bit
                Start-Sleep -Milliseconds 100
                continue
            }
            
            $line = $reader.ReadLine()
            if ($line -match "Welcome to the TeamSpeak 3 ServerQuery interface") {
                # Skip welcome message
                continue
            }
            
            [void]$response.AppendLine($line)
            
            # If we get an error line, we're done
            if ($line -match "error id=") {
                break
            }
        }
        
        $responseText = $response.ToString().Trim()
        Write-Host "Received response: $responseText" -ForegroundColor Cyan
        return $responseText
    }
    catch {
        Write-Host "Error in Send-TSCommand: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host "Creating limited query account group on $ServerIP`:$QueryPort..."

try {
    # Create TCP client with timeout
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connectionTask = $tcpClient.ConnectAsync($ServerIP, $QueryPort)
    
    # Set 5 second timeout for connection
    if (-not ($connectionTask.Wait(5000))) {
        Write-Host "Connection timed out!" -ForegroundColor Red
        exit 1
    }
    
    if (-not $tcpClient.Connected) {
        Write-Host "Failed to connect!" -ForegroundColor Red
        exit 1
    }
    
    $stream = $tcpClient.GetStream()
    $stream.ReadTimeout = 5000  # 5 second read timeout
    $stream.WriteTimeout = 5000  # 5 second write timeout
    
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)
    $writer.AutoFlush = $true
    
    # Read welcome message (2 lines)
    $welcome = $reader.ReadLine()
    $welcome2 = $reader.ReadLine()
    
    Write-Host "Connection successful."
    
    # Test connection
    $testConnection = Send-TSCommand "help" $tcpClient $reader $writer
    if ($null -eq $testConnection) {
        Write-Host "Failed to test connection" -ForegroundColor Red
        exit 1
    }
    
    # Login
    Write-Host "Logging in..."
    $loginResponse = Send-TSCommand "login $AdminUser $AdminPass" $tcpClient $reader $writer
    if ($null -eq $loginResponse) {
        Write-Host "Login command failed - no response from server" -ForegroundColor Red
        exit 1
    }
    if ($loginResponse -match "error id=0") {
        Write-Host "Login successful" -ForegroundColor Green
    } else {
        Write-Host "Login failed: $loginResponse" -ForegroundColor Red
        exit 1
    }
    
    # Select virtual server
    Write-Host "Selecting virtual server..."
    $useResponse = Send-TSCommand "use port=9987" $tcpClient $reader $writer
    if ($null -eq $useResponse -or -not ($useResponse -match "error id=0")) {
        Write-Host "Failed to select virtual server: $useResponse" -ForegroundColor Red
        exit 1
    }
    Write-Host "Virtual server selected" -ForegroundColor Green
    
    # Create server group
    Write-Host "Creating server group..."
    $groupResponse = Send-TSCommand "servergroupadd name=MyTSQueryAccess" $tcpClient $reader $writer
    if ($null -eq $groupResponse) {
        Write-Host "Group creation failed - no response from server" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Group creation response: $groupResponse"
    
    if ($groupResponse -match "error id=0") {
        # Extract the server group ID from the response
        $sgidMatch = $groupResponse | Select-String -Pattern "sgid=(\d+)" -AllMatches
        if ($sgidMatch.Matches.Count -gt 0) {
            $SGID = $sgidMatch.Matches[0].Groups[1].Value
            Write-Host "Created server group with ID: $SGID" -ForegroundColor Green
        } else {
            Write-Host "Created server group but couldn't extract ID" -ForegroundColor Yellow
            exit 1
        }
    } else {
        Write-Host "Failed to create server group: $groupResponse" -ForegroundColor Red
        exit 1
    }
    
    # Add permissions to the server group
    $permissions = @(
        "b_virtualserver_info_view",
        "b_virtualserver_channel_list",
        "b_virtualserver_client_list",
        "b_client_remoteaddress_view",
        "b_serverquery_login",
        "b_client_create_modify_serverquery_login"
    )
    
    Write-Host "Adding permissions..."
    foreach ($perm in $permissions) {
        $permResponse = Send-TSCommand "servergroupaddperm sgid=$SGID permsid=$perm permvalue=1 permnegated=0 permskip=0" $tcpClient $reader $writer
        if ($null -eq $permResponse) {
            Write-Host "Failed to add permission $perm - no response" -ForegroundColor Yellow
            continue
        }
        
        if ($permResponse -match "error id=0") {
            Write-Host "Added permission: $perm" -ForegroundColor Green
        } else {
            Write-Host "Failed to add permission $perm`: $permResponse" -ForegroundColor Yellow
        }
    }
    
    Write-Host "`nSuccess! Created server group with limited permissions:" -ForegroundColor Green
    Write-Host "Group Name: MyTSQueryAccess"
    Write-Host "Group ID: $SGID"
    Write-Host "Server: $ServerIP`:$QueryPort"
    Write-Host "`nYou can now assign this group to users who need query access."
}
finally {
    if ($reader) { $reader.Close() }
    if ($writer) { $writer.Close() }
    if ($stream) { $stream.Close() }
    if ($tcpClient -and $tcpClient.Connected) { $tcpClient.Close() }
}