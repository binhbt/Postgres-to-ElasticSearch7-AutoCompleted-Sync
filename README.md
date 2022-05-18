# Sync PostgreSQL with Elasticsearch via Debezium for AutoCompleted search(Search-As-You-Type)

### Schema

```
                   +-------------+
                   |             |
                   |  PostgreSQL |
                   |             |
                   +------+------+
                          |
                          |
                          |
          +---------------v------------------+
          |                                  |
          |           Kafka Connect          |
          |    (Debezium, ES connectors)     |
          |                                  |
          +---------------+------------------+
                          |
                          |
                          |
                          |
                  +-------v--------+
                  |                |
                  | Elasticsearch  |
                  |                |
                  +----------------+


```
We are using Docker Compose to deploy the following components:

* PostgreSQL
* Kafka
  * ZooKeeper
  * Kafka Broker
  * Kafka Connect with [Debezium](http://debezium.io/) and [Elasticsearch](https://github.com/confluentinc/kafka-connect-elasticsearch) Connectors
* Elasticsearch

### Usage

```shell
docker-compose up --build

# wait until it's setup
./start.sh
```

### Testing

Check database's content

```shell
# Check contents of the PostgreSQL database:
docker-compose exec postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DATABASE -c "SELECT * FROM users"'

# Check contents of the Elasticsearch database:
curl http://localhost:9200/users/_search?pretty
```

Create user

```shell
docker-compose exec postgres bash -c 'psql -U $POSTGRES_USER $POSTGRES_DATABASE'
test_db=# INSERT INTO users (email) VALUES ('apple@gmail.com');

# Check contents of the Elasticsearch database:
curl http://localhost:9200/users/_search?q=after.id:6
```

```json
{"took":0,"timed_out":false,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0},"hits":{"total":{"value":1,"relation":"eq"},"max_score":1.0,"hits":[{"_index":"users","_type":"_doc","_id":"6","_score":1.0,"_source":{"before":null,"after":{"id":6,"email":"apple@gmail.com"},"source":{"version":"1.3.1.Final","connector":"postgresql","name":"dbserver1","ts_ms":1652860481070,"snapshot":"false","db":"test_db","schema":"public","table":"users","txId":574,"lsn":24792832,"xmin":null},"op":"c","ts_ms":1652860483816,"transaction":null}}]}}
```

Update user

```shell
test_db=# UPDATE users SET email = 'tesla@gmail.com' WHERE id = 6;

# Check contents of the Elasticsearch database:
curl http://localhost:9200/users/_search?q=after.id:6
```

```json
{"took":62,"timed_out":false,"_shards":{"total":1,"successful":1,"skipped":0,"failed":0},"hits":{"total":{"value":1,"relation":"eq"},"max_score":1.0,"hits":[{"_index":"users","_type":"_doc","_id":"6","_score":1.0,"_source":{"before":null,"after":{"id":6,"email":"tesla@gmail.com"},"source":{"version":"1.3.1.Final","connector":"postgresql","name":"dbserver1","ts_ms":1652860617472,"snapshot":"false","db":"test_db","schema":"public","table":"users","txId":575,"lsn":24793872,"xmin":null},"op":"u","ts_ms":1652860617949,"transaction":null}}]}}
```

Delete user

```shell
test_db=# DELETE FROM users WHERE id = 6;

# Check contents of the Elasticsearch database:
curl http://localhost:9200/users/_search?q=after.id:6
```

```json
{
  ...
  "hits": {
    "total": 1,
    "max_score": 1.0,
    "hits": []
  }
}
```
# Test for auto suggestion search  
```shell
$cat search.sh  
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
```  
```shell  
$bash search.sh 
u
"user_2@yahoo.com"
"user_3@hotmail.com"
"user_4@hotmail.com"
"user_5@gmail.com"
"user_1@hotmail.com"
```  
See result when you type on console  
# Ref  
https://coralogix.com/blog/elasticsearch-autocomplete-with-search-as-you-type/  
