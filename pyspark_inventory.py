#dse spark-submit pyspark_inventory.py


from pyspark.sql import Row, SQLContext
from pyspark import SparkContext, SparkConf
from pyspark.sql.functions import lit

# simple python code to see a spark-submit


conf = SparkConf().setAppName("Extract UIDs")

sc = SparkContext(conf=conf)
sqlContext = SQLContext(sc)


def getData():
   items_sold_by_store_ = sqlContext.read.format("org.apache.spark.sql.cassandra").options(table="items_sold_by_store", keyspace="atwater").load()
   items_sold_by_store_.registerTempTable("my_temp_sales")
   items_sold_by_store = sqlContext.sql("select store_id, date, product_id, -quantity as quantity from my_temp_sales  where date < '2018-08-17'")
   items_sold_by_store.groupby(['store_id','product_id']).agg({'quantity': 'sum'}).withColumnRenamed("sum(quantity)", "quantity").withColumn('date', lit('2018-08-16')).write.format("org.apache.spark.sql.cassandra").options(table="store_inventory", keyspace = "atwater").save(mode ="append")

   sc.stop()


if __name__ == "__main__":
   getData()
