//source '/home/py/code/atwater/schema.cql';
DROP KEYSPACE atwater;

CREATE KEYSPACE atwater WITH REPLICATION =
        {'class': 'SimpleStrategy',
        'replication_factor': 1};
USE atwater;

CREATE TABLE products
   (
   product_id         uuid,
   name               text,
   description        text,
   UCP                text,
   price              decimal,
   color              text,
//   dimensions         text,
//   weight             text,
   category           text,
//   sub_category       text,
   PRIMARY KEY (product_id)
   );

//SELECT * FROM products;

CREATE TABLE orders_info
   (
   order_id           timeuuid,
   customer_id        uuid,
   store_id           uuid,
   status             text,
   address            text,
   postcode           text,
   city               text,
   state              text,
   country            text,
   email              text,
   phone_number       text,
   total_amount       decimal,
   checkout_timestamp timestamp,
   PRIMARY KEY ((order_id), customer_id)
   );

CREATE MATERIALIZED VIEW orders_info_by_customer
AS SELECT customer_id, order_id, store_id, status, checkout_timestamp, total_amount
FROM orders_info
WHERE customer_id IS NOT NULL
PRIMARY KEY ((customer_id), order_id)
WITH CLUSTERING ORDER BY (order_id DESC);


//drop MATERIALIZED VIEW items_sold_by_store;
//drop MATERIALIZED VIEW items_sold_by_product;
//drop TABLE orders_details;

CREATE TABLE orders_details
   (
   order_id           timeuuid,
   store_id           uuid,
   product_id         uuid,
   quantity           int,
   amount             decimal,
   checkout_id        timeuuid,
   checkout_timestamp timestamp,
   date               date,
   PRIMARY KEY ((order_id, store_id), product_id, date)
   );

CREATE MATERIALIZED VIEW items_sold_by_product
AS SELECT product_id, store_id, checkout_id, order_id, quantity, date
FROM orders_details
WHERE product_id IS NOT NULL AND store_id IS NOT NULL AND checkout_id IS NOT NULL 
AND order_id IS NOT NULL AND date IS NOT NULL
PRIMARY KEY ((product_id, date), store_id, checkout_id, order_id)
WITH CLUSTERING ORDER BY (checkout_id DESC, order_id DESC);

CREATE MATERIALIZED VIEW items_sold_by_store
AS SELECT product_id, store_id, checkout_id, order_id, quantity, checkout_timestamp, date
FROM orders_details
WHERE product_id IS NOT NULL AND store_id IS NOT NULL AND checkout_id IS NOT NULL 
AND order_id IS NOT NULL AND date IS NOT NULL
PRIMARY KEY ((store_id, date), checkout_id, product_id, order_id)
WITH CLUSTERING ORDER BY (checkout_id DESC, order_id DESC);

CREATE TABLE store_inventory
   (
   store_id           uuid,
   date               date,
   product_id         uuid,
   quantity           int,
   PRIMARY KEY ((store_id, date), product_id)
   );

CREATE MATERIALIZED VIEW product_inventory
AS SELECT product_id, store_id, date, quantity
FROM store_inventory
WHERE product_id IS NOT NULL AND store_id IS NOT NULL AND date IS NOT NULL
PRIMARY KEY ((product_id, date), store_id)
WITH CLUSTERING ORDER BY (date DESC);

CREATE TABLE customers
   (
   customer_id        uuid,
   email              text,
   first_name         text,
   last_name          text,
   hashed_password    text,
   phone_number       text,
   address            text,
   postcode           text,
   city               text,
   state              text,
   country            text, 
   PRIMARY KEY ((customer_id))
   );

CREATE MATERIALIZED VIEW customer_by_email
AS SELECT email, customer_id
FROM customers
WHERE customer_id IS NOT NULL AND email IS NOT NULL 
PRIMARY KEY ((email), customer_id);

CREATE TABLE stores
   (
   store_id           uuid,
   name               text,
   address            text,
   postcode           text,
   city               text,
   state              text,
   country            text,
   phone_number       text,
   latlong            text,
   PRIMARY KEY ((store_id))
   );

CREATE TABLE reviews
   (
   product_id         uuid,
   customer_id        uuid,
   review             text,
   rating             tinyint,
   PRIMARY KEY ((product_id), customer_id)
   );

CREATE TABLE operators  
   (
   operator_id              uuid,
   operator_first_name      text,
   operator_last_name       text,
   PRIMARY KEY ((operator_id))
   );

CREATE TABLE orders_to_prepare
   (
   store_id                 uuid,
   checkout_id              uuid,
   order_id                 text,
   responsible_operator_id  uuid,
   PRIMARY KEY ((store_id), checkout_id)
   );



CREATE SEARCH INDEX ON stores WITH COLUMNS * { excluded:true };
//DROP SEARCH INDEX ON stores  ;

ALTER SEARCH INDEX SCHEMA ON stores
   ADD types.fieldType[@name='ft_latlong',
   @class='solr.LatLonType',
   @subFieldSuffix='_coord'];


ALTER SEARCH INDEX SCHEMA ON stores
   ADD types.fieldType[@name=
   'ft_double', @class='solr.TrieDoubleField'];

ALTER SEARCH INDEX SCHEMA ON stores
   ADD dynamicField[@name=
   '*_coord', @type='ft_double',
   @indexed='true', @stored='false'];

ALTER SEARCH INDEX SCHEMA ON stores
   ADD fields.field[@name=
   'latlong', @type='ft_latlong',
   @indexed='true', @multiValued='false',
   @stored='true'];

RELOAD  SEARCH INDEX ON stores;
REBUILD SEARCH INDEX ON stores;


CREATE SEARCH INDEX ON products WITH COLUMNS * { excluded : true };
//DROP SEARCH INDEX ON products;

ALTER SEARCH INDEX SCHEMA ON products
   ADD types.fieldType[@name='TextField_phonetic',
   @class='solr.TextField'] with
      '{"analyzer":{"tokenizer":
       {"class":"solr.StandardTokenizerFactory"},
       "filter":{"class":"solr.BeiderMorseFilterFactory",
       "nameType":"GENERIC", "ruleType":"APPROX",
       "concat":"true", "languageSet":"auto"}}}';

ALTER SEARCH INDEX SCHEMA ON products
   ADD types.fieldType[@name='TextField_exact',
   @class='solr.TextField'] with
      '{"analyzer":{"tokenizer":
       {"class":"solr.StandardTokenizerFactory"},
       "filter":{"class":"solr.LowerCaseFilterFactory"}}}';

ALTER SEARCH INDEX SCHEMA ON products
        ADD fields.field[@name='name',
        @type='TextField_phonetic', @indexed='true',
        @multiValued='false',
        @stored='false'];

ALTER SEARCH INDEX SCHEMA ON products
        ADD fields.field[@name='description',
        @type='TextField_exact', @indexed='true',
        @multiValued='false',
        @stored='false'];

RELOAD  SEARCH INDEX ON products;
REBUILD SEARCH INDEX ON products;

SELECT name,product_id FROM products WHERE solr_query ='{ "q" : "(name:train)"  }' limit 10;
SELECT name,product_id FROM products WHERE solr_query ='{ "q" : "(description:train)"  }' limit 10;
SELECT name, product_id FROM products WHERE solr_query ='{ "q" : "(name:train^8  OR  description:train)" }' limit 10;

