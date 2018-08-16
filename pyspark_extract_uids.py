#


from pyspark.sql import Row, SQLContext
from pyspark import SparkContext, SparkConf


# simple python code to see a spark-submit


conf = SparkConf().setAppName("Extract UIDs")

sc = SparkContext(conf=conf)
sqlContext = SQLContext(sc)


def getData():
   stores = sqlContext.read.format("org.apache.spark.sql.cassandra").options(table="stores", keyspace="atwater").load()
   stores.registerTempTable("my_temp_s")
   stores_rdd = sqlContext.sql("select store_id from my_temp_s")
   stores_rdd.coalesce(1).write.csv("file:/home/py/data/atwater/stores_ids", header=True, mode='overwrite')
   #stores_rdd.show()
   customers = sqlContext.read.format("org.apache.spark.sql.cassandra").options(table="customers", keyspace="atwater").load()
   customers.registerTempTable("my_temp_c")
   customers_rdd = sqlContext.sql("select customer_id, address, postcode, city, state, country, phone_number, email from my_temp_c")
   customers_rdd.coalesce(1).write.csv("file:/home/py/data/atwater/customers_ids", header=True, mode='overwrite')
   #customers_rdd.show()
   products = sqlContext.read.format("org.apache.spark.sql.cassandra").options(table="products", keyspace="atwater").load()
   products.registerTempTable("my_temp_p")
   products_rdd = sqlContext.sql("select product_id from my_temp_p")
   products_rdd.coalesce(1).write.csv("file:/home/py/data/atwater/products_ids", header=True, mode='overwrite')
   #products_rdd.show()
      #
   sc.stop()


if __name__ == "__main__":
   getData()
