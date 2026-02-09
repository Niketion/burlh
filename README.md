# burl - Client HTTP/HTTPS in Bash

Client HTTP/HTTPS minimale in Bash puro.

## Sintassi

```bash
burl URL [HEADERS] [METHOD] [DATA]
```

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| URL | - | URL completo (http:// o https://) |
| HEADERS | "" | Header personalizzati (separati da newline) |
| METHOD | GET | GET, POST, PUT, DELETE, ecc. |
| DATA | "" | Body della richiesta |

**Output:** headers → stderr, body → stdout

## Esempi base

### GET
```bash
burl "https://httpbin.org/get" ""
```

### POST con JSON
```bash
burl "https://httpbin.org/post" "Content-Type: application/json" "POST" '{"key":"value"}'
```
Invia JSON a endpoint. `Content-Type` specifica formato, `POST` è il metodo, ultimo parametro è il body.

### Header multipli
```bash
burl "https://api.example.com/data" "Authorization: Bearer xyz123
Accept: application/json
X-Custom: header" "GET"
```
Header separati da newline (`\n`). Usato per auth, content negotiation, header custom.

### PUT
```bash
burl "https://api.example.com/resource/123" "Content-Type: application/json" "PUT" '{"status":"updated"}'
```
Aggiorna risorsa esistente con nuovo stato.

### DELETE
```bash
burl "https://api.example.com/resource/123" "Authorization: Bearer xyz123" "DELETE"
```
Richiede auth, cancella risorsa.

## Esempi avanzati

### Redirect automatici
```bash
burl "http://httpbin.org/redirect/3" ""
```
Segue automaticamente fino a 5 redirect. Output mostra tutti i passaggi su stderr.

### Chunked transfer encoding
```bash
burl "https://httpbin.org/stream/5" "" | jq -r '.id'
```
Decodifica automaticamente chunked encoding. Usa `dd` per lettura byte-accurate dei chunk.

### Pipe a jq
```bash
burl "https://httpbin.org/get" "" | jq '.headers["User-Agent"]'
```
Body JSON va su stdout, jq parsea direttamente.

### Solo body
```bash
burl "https://httpbin.org/image/png" "" > image.png 2>/dev/null
```
`2>/dev/null` sopprime headers (stderr), salva solo body.

### Solo headers
```bash
burl "https://httpbin.org/get" "" >/dev/null
```
`>/dev/null` elimina body, mostra solo headers.

### Headers e body separati
```bash
burl "https://httpbin.org/get" "" > body.json 2> headers.txt
```
Redirect separati: body in file, headers in altro.

### Conta redirect
```bash
burl "http://httpbin.org/redirect/3" "" 2>&1 | grep -c "HTTP/1.1"
```
`2>&1` merge stderr in stdout, conta response HTTP totali (redirect + finale).

### Estrai header specifico
```bash
burl "https://httpbin.org/get" "" 2>&1 | grep -i "^content-type:"
```
Cerca header case-insensitive nella risposta.

### Loop su endpoint
```bash
for i in {1..3}; do 
    burl "https://httpbin.org/get?id=$i" "" | jq -r ".args.id"
done
```
Itera su query param, estrae valore da ogni risposta JSON.

### Misura tempo
```bash
time burl "https://httpbin.org/delay/2" "" >/dev/null
```
Endpoint con delay di 2 secondi, `time` misura durata totale.

### Bearer token auth
```bash
burl "https://httpbin.org/bearer" "Authorization: Bearer test_token" ""
```
Auth con token, endpoint verifica presenza header.

### Debug completo
```bash
burl "https://httpbin.org/post" "Content-Type: application/json" "POST" '{"test":"data"}' 2>&1 | less
```
`2>&1` mostra tutto (headers + body), `less` per navigare output.

## Come funziona

### Parsing URL
```bash
scheme="${u%%://*}"      # http o https
host="${hostport%%:*}"   # hostname
port="${hostport#*:}"    # porta (80/443 default)
path="/${u#*/}"          # /path/to/resource
```
Parameter expansion bash per split efficiente.

### Formato HTTP
```
GET /path HTTP/1.1\r\n
Host: example.com\r\n
User-Agent: burl/1.0\r\n
Connection: close\r\n
\r\n
```
CRLF (`\r\n`) obbligatorio per RFC 7230. Usato `printf`, non `echo`.

### TLS
```bash
openssl s_client -quiet -connect "$host:$port" -servername "$host"
```
`-servername` attiva SNI per virtual hosting HTTPS.

### Chunked decoding
```
size_hex\r\n
data[size]\r\n
0\r\n
```
Legge size hex, converte in decimale (`$((16#$size))`), usa `dd bs=1 count=$size` per leggere esattamente N bytes (preserva newline interni).

### Redirect
Detecta 3xx status code, estrae Location header, converte path relativi in assoluti (`$scheme://$host$location`), max 5 iterazioni.

## Limitazioni

**Non supportato:**
- HTTP/2, HTTP/3
- Compressione (gzip, deflate, brotli)
- Keep-alive / connection reuse
- Cookie storage
- Auth schemes (Basic, Digest, OAuth)
- Certificate validation
- Proxy
- Multipart/form-data
- WebSocket

**Production:** usa `curl` o `wget`.

## Riferimenti

- [RFC 9110 - HTTP Semantics](https://datatracker.ietf.org/doc/html/rfc9110)
- [RFC 7230 - HTTP/1.1 Syntax](https://datatracker.ietf.org/doc/html/rfc7230)
- [RFC 7230 §4.1 - Chunked Transfer](https://datatracker.ietf.org/doc/html/rfc7230#section-4.1)