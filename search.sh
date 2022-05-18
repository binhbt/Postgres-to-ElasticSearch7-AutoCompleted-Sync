while true
do
 IFS= read -rsn1 char
 INPUT=$INPUT$char
 echo $INPUT
 curl --silent --request GET 'http://localhost:9200/users/_search' \
 --header 'Content-Type: application/json' \
 --data-raw '{
     "size": 5,
     "query": {
         "multi_match": {
             "query": "'"$INPUT"'",
             "type": "bool_prefix",
             "fields": [
                 "after.email",
                 "after.email._2gram",
                 "after.email._3gram"
             ]
         }
     }
 }' | jq .hits.hits[]._source.after.email | grep -i "$INPUT"
done
