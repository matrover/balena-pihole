# balena-pihole

Pi-hole voor balenaCloud, uitgebreid met:

- een `hostname` service die de balena device name kan toepassen als netwerk-hostname
- een `public-web` proxy die balena's Public Device URL naar Pi-hole `/admin/` stuurt
- een optionele `tailscale` service voor externe toegang

## Services

- `pihole`: de Pi-hole DNS- en webservice
- `hostname`: zet de hostnaam van het device via de Supervisor API
- `public-web`: luistert op poort `80` en redirect `/` naar `/admin/`
- `tailscale`: optionele Tailscale sidecar

## Gebruik

Na deployment kun je Pi-hole lokaal bereiken via:

- `http://pihole.local/admin/`
- `http://<device-ip>/admin/`

Als je in balenaCloud de Public Device URL aanzet voor het device, dan komt die
uit op poort `80` van `public-web`, die vervolgens `/` doorstuurt naar
`/admin/`.

## Variabelen

| Name | Default | Purpose |
| --- | --- | --- |
| `FTLCONF_webserver_api_password` | `balena` | Wachtwoord voor de Pi-hole admininterface. |
| `FTLCONF_dns_upstreams` | `1.1.1.1;1.0.0.1` | Upstream DNS servers voor Pi-hole. |
| `SET_HOSTNAME` | `device-name` | Gebruik `device-name` voor de balena device name, `uuid` voor de korte device UUID, of een vaste hostname. |
| `TAILSCALE_AUTH_KEY` | `` | Auth key voor de optionele Tailscale service. |
| `TAILSCALE_HOSTNAME` | `pi-hole` | Node-naam binnen Tailscale. |
| `TAILSCALE_ADVERTISE_ROUTES` | `` | Optionele subnet routes voor Tailscale. |
| `TAILSCALE_ACCEPT_ROUTES` | `false` | Zet op `true` om routes van andere Tailscale nodes te accepteren. |

## Push Naar Balena

Deze machine gebruikt geen `git` voor deployments. Push altijd rechtstreeks
met `balena push`.

### Doelfleet

- Fleet slug: `m15/pi4-pihole`

### Standaard workflow

1. Open een terminal in de root van dit project.
2. Push altijd met `balena push` naar `m15/pi4-pihole`.
3. Geef altijd de wijziging mee in `--release-tag`.
4. Controleer na elke push altijd de logs van het device.

### Login

Log in indien nodig:

```powershell
balena login
```

### Push commando

Gebruik altijd een release-tag waarin de wijziging herkenbaar staat.

Voorbeelden:

```powershell
balena push m15/pi4-pihole --release-tag changes hostname-device-name
balena push m15/pi4-pihole --release-tag changes pihole-admin-public-url
balena push m15/pi4-pihole --release-tag changes tailscale-route-fix
```

### Devices in de fleet bekijken

Zoek na een push eerst het device op:

```powershell
balena device list --fleet m15/pi4-pihole
```

### Logs altijd controleren na push

Controleer na elke push of de services goed opstarten:

```powershell
balena device logs <device-uuid> --tail
```

Handige service-specifieke checks:

```powershell
balena device logs <device-uuid> --tail --service pihole
balena device logs <device-uuid> --tail --service public-web
balena device logs <device-uuid> --tail --service hostname
balena device logs <device-uuid> --tail --service tailscale
```

Controleer in elk geval:

- dat `pihole` zonder fouten opstart
- dat `public-web` draait en `/` naar `/admin/` redirect
- dat `hostname` geen Supervisor API fout meldt
- dat `tailscale` alleen draait als deze geconfigureerd is

## Hostname Gedrag

De `hostname` service gebruikt standaard `SET_HOSTNAME=device-name`. Daarmee
wordt de actuele balena device name opgehaald via de Supervisor API en
omgezet naar een geldige netwerk-hostname.

## Tailscale

De `tailscale` service is optioneel. Zet `TAILSCALE_AUTH_KEY` om hem te
activeren. Je kunt daarnaast `TAILSCALE_HOSTNAME`,
`TAILSCALE_ADVERTISE_ROUTES` en `TAILSCALE_ACCEPT_ROUTES` gebruiken.

## Referenties

Deze workflow en commando's zijn afgestemd op de officiele balena CLI
documentatie:

- https://docs.balena.io/reference/balena-cli/
- https://docs.balena.io/management/devices/

Pi-hole documentatie:

- https://docs.pi-hole.net/
