# TeamSpeak Query Account Creator

A PowerShell script to automate the creation of limited permission groups for TeamSpeak 3 servers. This script is specifically designed to create server groups that can be used with [My-TS.org](https://www.my-ts.org) for query login functionality.

## Description

This script creates a server group (MyTSQueryAccess) with limited permissions that you can assign to specific users on your TeamSpeak server. These users can then create query logins to use with My-TS.org services.

### Features

- Creates a server group with carefully selected permissions
- Automates the TeamSpeak ServerQuery interface interaction
- Maintains a single connection for reliable command execution
- Provides clear feedback and error handling
- Supports custom server configurations

## Prerequisites

- PowerShell 5.0 or higher
- TeamSpeak 3 Server with ServerQuery enabled
- ServerAdmin access to your TeamSpeak server

## Installation

1. Clone this repository or download the script
2. Ensure you have the required permissions on your TeamSpeak server

## Usage

Run the script with the following parameters:

```powershell
.\createquery.ps1 -ServerIP "your.server.ip" -QueryPort 10011 -AdminUser "serveradmin" -AdminPass "your_password"
```

### Parameters

- `ServerIP`: The IP address of your TeamSpeak server
- `QueryPort`: The ServerQuery port (default is 10011)
- `AdminUser`: Your ServerAdmin username
- `AdminPass`: Your ServerAdmin password

### Created Permissions

The script creates a server group with the following permissions:

- `b_virtualserver_info_view`: View server information
- `b_virtualserver_channel_list`: List channels
- `b_virtualserver_client_list`: List clients
- `b_client_remoteaddress_view`: View client IP addresses
- `b_serverquery_login`: Allow server query login
- `b_client_create_modify_serverquery_login`: Create and modify query logins

## Security Notes

- Never share your ServerAdmin credentials
- Use this script only on servers you own or have permission to modify
- Consider using environment variables or a secure credential store for sensitive information

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Copyright

© 2024 My-TS.org. All rights reserved.

## Support

For support, please visit [My-TS.org](https://www.my-ts.org) or open an issue in this repository.
