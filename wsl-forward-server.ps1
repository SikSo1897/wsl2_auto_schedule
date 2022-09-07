#https://github.com/microsoft/WSL/issues/4150#issuecomment-504209723
echo "wsl-forward-server.ps1 run";

$remoteport = bash.exe -c "ifconfig eth0 | grep 'inet '"
echo "[get-remoteport] $remoteport";

$found = $remoteport -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';

if( $found ){
    $remoteport = $matches[0];
    echo "[parse-remoteport] $remoteport";

} else{
    echo "The Script Exited, the ip address of WSL 2 cannot be found";
    exit;
}

#[Ports]
#All the ports you want to forward separated by coma
# $ports=@(80, 443, 10000, 3000, 5000); # Default Option
$path_to_port = "$PSScriptRoot\secret.ports"
$ports = @(Get-Content -LiteralPath $path_to_port)

#[Static ip]
#You can change the addr to your ip config to listen to a specific address
$addr='0.0.0.0';
$ports_a = $ports -join ",";

#Remove Firewall Exception Rules
echo "[Remove-NetFireWallRule] result"
iex "Remove-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' ";

#adding Exception Rules for inbound and outbound Rules
echo "[New-NetFireWallRule] WSL 2 Firewall Unlock Outbound -LocalPort"
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Outbound -LocalPort $ports_a -Action Allow -Protocol TCP";

echo "[New-NetFireWallRule] WSL 2 Firewall Unlock Inbound -LocalPort"
iex "New-NetFireWallRule -DisplayName 'WSL 2 Firewall Unlock' -Direction Inbound -LocalPort $ports_a -Action Allow -Protocol TCP";

for( $i = 0; $i -lt $ports.length; $i++ ){
  $port = $ports[$i];
    echo "[netsh-run] interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport"
  iex "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$addr connectport=$port connectaddress=$remoteport";
}

wsl.exe echo "[WSL] openssh restarting..."
wsl.exe -u root sudo service ssh --full-restart
wsl.exe -u root sudo service ssh restart
