#!/bin/sh
set -eu
LC_ALL=C
file=$1

u32() {
  od -An -t u4 -N 4 -j "$1" "$file" | tr -cd 0-9
}
u64() {
  od -An -t u8 -N 8 -j "$1" "$file" | tr -cd 0-9
}

replace() {
  old=$1
  new=$2
  [ ${#old} -eq ${#new} ] || {
    echo "length ${#old} != ${#new}" >&2
    exit 1
  }
  count=$(grep -a -o -F -e "$old" "$file" | wc -l)
  [ "$count" -eq 1 ] || {
    echo "expected 1 match, found $count" >&2
    exit 1
  }
  off=$(grep -a -b -o -F -e "$old" "$file" | cut -d: -f1)
  printf '%s' "$new" | dd of="$file" bs=1 seek="$off" conv=notrunc status=none
  printf '%s\n' "$off"
}

zero_bytecode() {
  needle_off=$1
  mark=$(grep -a -b -o -F -e '---- Bun! ----' "$file" | tail -1 | cut -d: -f1)
  trailer=$((mark - 1))
  base=$((trailer - 32))
  byte_count=$(u64 "$base")
  mod_off=$(u32 $((base + 8)))
  mod_len=$(u32 $((base + 12)))
  [ $((mod_len % 52)) -eq 0 ] && [ "$byte_count" -gt 0 ] || {
    echo "unexpected bun module table" >&2
    exit 1
  }
  data=$((trailer + 16 - byte_count))
  rel=$((needle_off - data))
  table=$((data + mod_off))
  slot=$(od -v -An -t u4 -N "$mod_len" -j "$table" "$file" | awk -v rel="$rel" '
    { for (i = 1; i <= NF; i++) f[++n] = $i }
    END {
      hit = 0
      recs = int(n / 13)
      for (r = 0; r < recs; r++) {
        b = r * 13
        coff = f[b + 4]
        clen = f[b + 5]
        if (clen > 0 && rel >= coff && rel < coff + clen) {
          hit++
          slot = (b + 8) * 4
        }
      }
      if (hit != 1) {
        printf "expected 1 module, found %d\n", hit > "/dev/stderr"
        exit 2
      }
      print slot
    }')
  printf '\0\0\0\0' | dd of="$file" bs=1 seek=$((table + slot)) conv=notrunc status=none
}

off=$(replace \
  'function x(){if(process.env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC)return"essential-traffic";if(process.env.DISABLE_TELEMETRY)return"no-telemetry";if(Pe(process.env.DO_NOT_TRACK))return"no-telemetry";return"default"}' \
  'function x(){if(1||process.env.CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAF)return"essential-traffic";if(process.env.DISABLE_TELEMETRY)return"no-telemetry";if(Pe(process.env.DO_NOT_TRACK))return"no-telemetry";return"default"}')
zero_bytecode "$off"

off=$(replace \
  'function Yie(){if(a.DISABLE_UPDATES)return{type:"env",envVar:"DISABLE_UPDATES"}' \
  'function Yie(){if(1||a.DISABLE_UPDA)return{type:"env",envVar:"DISABLE_UPDATES"}')
zero_bytecode "$off"
