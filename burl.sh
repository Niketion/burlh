burl() {
    local method="${3:-GET}" data="$4" u="$1" h="$2"
    local scheme host port path status_code location redirect_count=0
    
    while [[ $redirect_count -lt 5 ]]; do
        scheme="${u%%://*}"
        u="${u#*://}"
        hostport="${u%%/*}"
        path="/${u#*/}"
        [[ "$hostport" == "$u" ]] && path="/"
        host="${hostport%%:*}"
        port="${hostport#*:}"
        [[ "$host" == "$port" ]] && { [[ "$scheme" == "https" ]] && port=443 || port=80; }
        
        local req=$(mktemp) res=$(mktemp)
        {
            printf '%s %s HTTP/1.1\r\n' "$method" "$path"
            printf 'Host: %s\r\nUser-Agent: burl/1.0\r\nConnection: close\r\n' "$host"
            [[ -n "$h" ]] && printf '%s\r\n' "$h"
            [[ -n "$data" ]] && printf 'Content-Length: %d\r\n' "${#data}"
            printf '\r\n%s' "$data"
        } > "$req"
        
        if [[ "$scheme" == "https" ]]; then
            openssl s_client -quiet -connect "$host:$port" -servername "$host" < "$req" > "$res" 2>/dev/null
        else
            nc "$host" "$port" < "$req" > "$res" 2>/dev/null
        fi
        
        local chunked=0 body_start=0
        while IFS= read -r line; do
            line="${line%$'\r'}"
            ((body_start++))
            echo "$line" >&2
            [[ -z "$status_code" ]] && status_code=$(echo "$line" | cut -d' ' -f2)
            [[ "$line" =~ ^[Ll]ocation:\ (.+)$ ]] && location="${BASH_REMATCH[1]}"
            [[ "$line" =~ ^[Tt]ransfer-[Ee]ncoding:.*chunked ]] && chunked=1
            [[ -z "$line" ]] && break
        done < "$res"
        
        if [[ $chunked -eq 1 ]]; then
            tail -n +$((body_start + 1)) "$res" | {
                while IFS= read -r size_line; do
                    size_line="${size_line%$'\r'}"
                    [[ ! "$size_line" =~ ^[0-9A-Fa-f]+$ ]] && continue
                    local sz=$((16#$size_line))
                    [[ $sz -eq 0 ]] && break
                    dd bs=1 count=$sz 2>/dev/null
                    read -r
                done
            }
        else
            tail -n +$((body_start + 1)) "$res"
        fi
        
        rm -f "$req" "$res"
        
        if [[ "$status_code" =~ ^3[0-9]{2}$ && -n "$location" ]]; then
            ((redirect_count++))
            [[ ! "$location" =~ ^https?:// ]] && location="$scheme://$host$location"
            echo >&2 "→ Redirect: $location"
            u="$location"
            status_code=""
        else
            break
        fi
    done
}
