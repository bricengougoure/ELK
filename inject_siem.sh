#!/bin/bash
# ============================================================
# Script d'injection de 50 documents SIEM dans Elasticsearch
# Usage: bash inject_siem.sh <MOT_DE_PASSE_ELASTIC>
# ============================================================

ES_PASS=${1:-"changeme"}
ES_URL="https://127.0.0.1:9200"
CA_CERT="/etc/elasticsearch/certs/http_ca.crt"
BULK_FILE="siem_bulk_50docs.ndjson"

echo "============================================"
echo " Injection des 50 documents SIEM"
echo "============================================"

# Créer l'index avec mapping
echo "[1/3] Création de l'index siem-logs-2026.03.15..."
curl -s -u elastic:${ES_PASS} \
  --cacert ${CA_CERT} \
  -X PUT "${ES_URL}/siem-logs-2026.03.15" \
  -H "Content-Type: application/json" -d '
{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  },
  "mappings": {
    "properties": {
      "@timestamp":            { "type": "date" },
      "source.ip":             { "type": "ip" },
      "destination.ip":        { "type": "ip" },
      "event.category":        { "type": "keyword" },
      "event.outcome":         { "type": "keyword" },
      "event.severity":        { "type": "integer" },
      "event.risk_score":      { "type": "integer" },
      "message":               { "type": "text" },
      "user.name":             { "type": "keyword" },
      "host.name":             { "type": "keyword" },
      "network.protocol":      { "type": "keyword" },
      "tags":                  { "type": "keyword" },
      "source.geo.location":   { "type": "geo_point" }
    }
  }
}' | python3 -m json.tool
echo ""

# Injecter les documents
echo "[2/3] Injection des 50 documents via API Bulk..."
curl -s -u elastic:${ES_PASS} \
  --cacert ${CA_CERT} \
  -X POST "${ES_URL}/_bulk" \
  -H "Content-Type: application/x-ndjson" \
  --data-binary @${BULK_FILE} | python3 -m json.tool | grep -E '"result"|"errors"|"status"' | head -20
echo ""

# Vérification
echo "[3/3] Vérification du nombre de documents indexés..."
curl -s -u elastic:${ES_PASS} \
  --cacert ${CA_CERT} \
  "${ES_URL}/siem-logs-2026.03.15/_count?pretty"
echo ""

echo "============================================"
echo " Injection terminée !"
echo " Vérifiez dans Kibana : siem-logs-2026.03.15"
echo "============================================"
