package com.hbasegui.bridge;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.PrefixFilter;
import org.apache.hadoop.hbase.util.Bytes;

import java.io.IOException;
import java.util.*;

public class HBaseBridge {
    private static Connection connection;
    private static Admin admin;

    public static synchronized boolean connect(String zkQuorum, String zkNode) {
        try {
            Configuration config = HBaseConfiguration.create();
            config.set("hbase.zookeeper.quorum", zkQuorum);
            config.set("zookeeper.znode.parent", zkNode);

            connection = ConnectionFactory.createConnection(config);
            admin = connection.getAdmin();
            return true;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }

    public static synchronized void disconnect() {
        try {
            if (admin != null) {
                admin.close();
            }
            if (connection != null) {
                connection.close();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static List<String> listTables() {
        List<String> tables = new ArrayList<>();
        try {
            TableName[] tableNames = admin.listTableNames();
            for (TableName tableName : tableNames) {
                tables.add(tableName.getNameAsString());
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return tables;
    }

    public static List<Map<String, String>> getTableData(String tableName, String startRow, String endRow, int limit, String filterPrefix) {
        List<Map<String, String>> result = new ArrayList<>();
        try {
            Table table = connection.getTable(TableName.valueOf(tableName));
            Scan scan = new Scan();
            
            if (startRow != null && !startRow.isEmpty()) {
                scan.withStartRow(Bytes.toBytes(startRow));
            }
            if (endRow != null && !endRow.isEmpty()) {
                scan.withStopRow(Bytes.toBytes(endRow));
            }
            if (filterPrefix != null && !filterPrefix.isEmpty()) {
                scan.setFilter(new PrefixFilter(Bytes.toBytes(filterPrefix)));
            }
            if (limit > 0) {
                scan.setLimit(limit);
            }

            ResultScanner scanner = table.getScanner(scan);
            for (Result r : scanner) {
                NavigableMap<byte[], NavigableMap<byte[], NavigableMap<Long, byte[]>>> map = r.getMap();
                for (Map.Entry<byte[], NavigableMap<byte[], NavigableMap<Long, byte[]>>> familyEntry : map.entrySet()) {
                    String family = Bytes.toString(familyEntry.getKey());
                    for (Map.Entry<byte[], NavigableMap<Long, byte[]>> qualifierEntry : familyEntry.getValue().entrySet()) {
                        String qualifier = Bytes.toString(qualifierEntry.getKey());
                        for (Map.Entry<Long, byte[]> timestampEntry : qualifierEntry.getValue().entrySet()) {
                            Map<String, String> row = new HashMap<>();
                            row.put("rowKey", Bytes.toString(r.getRow()));
                            row.put("columnFamily", family);
                            row.put("column", qualifier);
                            row.put("value", Bytes.toString(timestampEntry.getValue()));
                            row.put("timestamp", String.valueOf(timestampEntry.getKey()));
                            result.add(row);
                        }
                    }
                }
            }
            scanner.close();
            table.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return result;
    }

    public static boolean executeCommand(String tableName, String command) {
        try {
            Table table = connection.getTable(TableName.valueOf(tableName));
            String[] parts = command.split("\\s+");
            
            switch (parts[0].toLowerCase()) {
                case "get":
                    if (parts.length < 2) return false;
                    String rowKey = parts[1].replace("\"", "");
                    Get get = new Get(Bytes.toBytes(rowKey));
                    Result result = table.get(get);
                    // 处理结果...
                    break;
                    
                case "put":
                    if (parts.length < 5) return false;
                    String putRowKey = parts[1].replace("\"", "");
                    String family = parts[2].replace("\"", "");
                    String qualifier = parts[3].replace("\"", "");
                    String value = parts[4].replace("\"", "");
                    
                    Put put = new Put(Bytes.toBytes(putRowKey));
                    put.addColumn(
                        Bytes.toBytes(family),
                        Bytes.toBytes(qualifier),
                        Bytes.toBytes(value)
                    );
                    table.put(put);
                    break;
                    
                case "delete":
                    if (parts.length < 2) return false;
                    String deleteRowKey = parts[1].replace("\"", "");
                    Delete delete = new Delete(Bytes.toBytes(deleteRowKey));
                    table.delete(delete);
                    break;
                    
                default:
                    return false;
            }
            
            table.close();
            return true;
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }
} 