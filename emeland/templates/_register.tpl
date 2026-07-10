{{/*
Sidecar container that continuously reconciles an event subscriber registration.
Publisher API URL must end with /api/ (e.g. http://emeland-filter:80/api/).
*/}}
{{- define "emeland.registerSubscriberContainer" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- $publisherApi := index . 2 -}}
{{- $callback := index . 3 -}}
- name: {{ $name }}
  image: {{ $root.Values.subscriptions.registerImage }}
  imagePullPolicy: IfNotPresent
  command:
    - sh
    - -c
    - |
      set -eu
      PUBLISHER_API="{{ $publisherApi }}"
      CALLBACK="{{ $callback }}"
      INTERVAL={{ $root.Values.subscriptions.reconcileIntervalSeconds }}
      until curl -sf "${PUBLISHER_API}events/subscribers" >/dev/null 2>&1; do
        echo "{{ $name }}: waiting for publisher API at ${PUBLISHER_API}..."
        sleep 2
      done
      echo "{{ $name }}: publisher API ready"
      while true; do
        if curl -sf "${PUBLISHER_API}events/subscribers" | grep -Fq "${CALLBACK}"; then
          sleep "${INTERVAL}"
          continue
        fi
        echo "{{ $name }}: registering subscriber ${CALLBACK}"
        curl -sf -X POST "${PUBLISHER_API}events/register" \
          -H "Content-Type: application/json" \
          -d "{\"callbackUrl\":\"${CALLBACK}\"}"
        echo "{{ $name }}: registration complete"
        sleep "${INTERVAL}"
      done
{{- end }}
