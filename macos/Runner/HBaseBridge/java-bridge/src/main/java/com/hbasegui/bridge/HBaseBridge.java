package com.hbasegui.bridge;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.*;
import org.apache.hadoop.hbase.filter.PrefixFilter;
import org.apache.hadoop.hbase.util.Bytes;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.util.*;

public class HBaseBridge {
    private static Connection connection = null;
    private static Admin admin = null;

    public static boolean connect(String zkQuorum, String zkNode) {
        try {
            System.out.println("【HBase连接】开始连接HBase...");
            System.out.println("【HBase连接】ZooKeeper地址: " + zkQuorum);
            System.out.println("【HBase连接】ZooKeeper节点: " + zkNode);

            Configuration config = HBaseConfiguration.create();
            config.set("hbase.zookeeper.quorum", zkQuorum);
            config.set("zookeeper.znode.parent", zkNode);

            connection = ConnectionFactory.createConnection(config);
            admin = connection.getAdmin();

            System.out.println("【HBase连接】连接成功");
            return true;
        } catch (IOException e) {
            System.err.println("【HBase连接】连接失败: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    public static void disconnect() {
        try {
            if (admin != null) {
                admin.close();
            }
            if (connection != null) {
                connection.close();
            }
            System.out.println("【HBase连接】已断开连接");
        } catch (IOException e) {
            System.err.println("【HBase连接】断开连接失败: " + e.getMessage());
            e.printStackTrace();
        }
    }

    public static String listTables() {
        try {
            System.out.println("【HBase操作】开始获取表列表...");
            List<String> tableNames = new ArrayList<>();
            for (TableName tableName : admin.listTableNames()) {
                tableNames.add(tableName.getNameAsString());
            }
            JSONArray jsonArray = new JSONArray(tableNames);
            System.out.println("【HBase操作】获取表列表成功，数量: " + tableNames.size());
            return jsonArray.toString();
        } catch (IOException e) {
            System.err.println("【HBase操作】获取表列表失败: " + e.getMessage());
            e.printStackTrace();
            return "[]";
        }
    }

    public static String getTableData(String tableName, String startRow, String endRow, int limit, String filterPrefix) {
        try {
            System.out.println("【HBase操作】开始获取表数据...");
            System.out.println("【HBase操作】表名: " + tableName);
            System.out.println("【HBase操作】起始行: " + startRow);
            System.out.println("【HBase操作】结束行: " + endRow);
            System.out.println("【HBase操作】限制数量: " + limit);
            System.out.println("【HBase操作】过滤前缀: " + filterPrefix);

            Table table = connection.getTable(TableName.valueOf(tableName));
            Scan scan = new Scan();
            
            if (startRow != null && !startRow.isEmpty()) {
                scan.withStartRow(Bytes.toBytes(startRow));
            }
            if (endRow != null && !endRow.isEmpty()) {
                scan.withStopRow(Bytes.toBytes(endRow));
            }
            if (filterPrefix != null && !filterPrefix.isEmpty()) {
                scan.setRowPrefixFilter(Bytes.toBytes(filterPrefix));
            }
            scan.setLimit(limit);

            ResultScanner scanner = table.getScanner(scan);
            JSONArray jsonArray = new JSONArray();
            int count = 0;

            for (Result result : scanner) {
                JSONObject rowJson = new JSONObject();
                rowJson.put("row", Bytes.toString(result.getRow()));

                JSONObject familiesJson = new JSONObject();
                for (Map.Entry<byte[], NavigableMap<byte[], byte[]>> familyEntry : result.getNoVersionMap().entrySet()) {
                    String family = Bytes.toString(familyEntry.getKey());
                    JSONObject qualifiersJson = new JSONObject();

                    for (Map.Entry<byte[], byte[]> qualifierEntry : familyEntry.getValue().entrySet()) {
                        String qualifier = Bytes.toString(qualifierEntry.getKey());
                        String value = Bytes.toString(qualifierEntry.getValue());
                        qualifiersJson.put(qualifier, value);
                    }

                    familiesJson.put(family, qualifiersJson);
                }
                rowJson.put("families", familiesJson);
                jsonArray.put(rowJson);

                if (++count >= limit) {
                    break;
                }
            }

            scanner.close();
            table.close();

            System.out.println("【HBase操作】获取表数据成功，数量: " + count);
            return jsonArray.toString();
        } catch (IOException e) {
            System.err.println("【HBase操作】获取表数据失败: " + e.getMessage());
            e.printStackTrace();
            return "[]";
        }
    }

    public static String executeCommand(String tableName, String command, String rowKey, String family, String qualifier, String value) {
        try {
            System.out.println("【HBase操作】开始执行命令...");
            System.out.println("【HBase操作】表名: " + tableName);
            System.out.println("【HBase操作】命令: " + command);
            System.out.println("【HBase操作】行键: " + rowKey);
            System.out.println("【HBase操作】列族: " + family);
            System.out.println("【HBase操作】列限定符: " + qualifier);
            System.out.println("【HBase操作】值: " + value);

            Table table = connection.getTable(TableName.valueOf(tableName));
            JSONObject result = new JSONObject();

            switch (command.toLowerCase()) {
                case "get":
                    Get get = new Get(Bytes.toBytes(rowKey));
                    if (family != null && !family.isEmpty()) {
                        if (qualifier != null && !qualifier.isEmpty()) {
                            get.addColumn(Bytes.toBytes(family), Bytes.toBytes(qualifier));
                        } else {
                            get.addFamily(Bytes.toBytes(family));
                        }
                    }
                    Result getResult = table.get(get);
                    if (!getResult.isEmpty()) {
                        JSONObject rowJson = new JSONObject();
                        rowJson.put("row", Bytes.toString(getResult.getRow()));

                        JSONObject familiesJson = new JSONObject();
                        for (Map.Entry<byte[], NavigableMap<byte[], byte[]>> familyEntry : getResult.getNoVersionMap().entrySet()) {
                            String fam = Bytes.toString(familyEntry.getKey());
                            JSONObject qualifiersJson = new JSONObject();

                            for (Map.Entry<byte[], byte[]> qualifierEntry : familyEntry.getValue().entrySet()) {
                                String qual = Bytes.toString(qualifierEntry.getKey());
                                String val = Bytes.toString(qualifierEntry.getValue());
                                qualifiersJson.put(qual, val);
                            }

                            familiesJson.put(fam, qualifiersJson);
                        }
                        rowJson.put("families", familiesJson);
                        result.put("data", rowJson);
                    }
                    break;

                case "put":
                    Put put = new Put(Bytes.toBytes(rowKey));
                    if (family != null && !family.isEmpty() && qualifier != null && !qualifier.isEmpty() && value != null) {
                        put.addColumn(Bytes.toBytes(family), Bytes.toBytes(qualifier), Bytes.toBytes(value));
                        table.put(put);
                        result.put("status", "success");
                    } else {
                        result.put("status", "error");
                        result.put("message", "Missing required parameters for put operation");
                    }
                    break;

                case "delete":
                    Delete delete = new Delete(Bytes.toBytes(rowKey));
                    if (family != null && !family.isEmpty()) {
                        if (qualifier != null && !qualifier.isEmpty()) {
                            delete.addColumn(Bytes.toBytes(family), Bytes.toBytes(qualifier));
                        } else {
                            delete.addFamily(Bytes.toBytes(family));
                        }
                    }
                    table.delete(delete);
                    result.put("status", "success");
                    break;

                default:
                    result.put("status", "error");
                    result.put("message", "Unsupported command: " + command);
            }

            table.close();
            System.out.println("【HBase操作】命令执行完成");
            return result.toString();
        } catch (IOException e) {
            System.err.println("【HBase操作】命令执行失败: " + e.getMessage());
            e.printStackTrace();
            JSONObject errorResult = new JSONObject();
            errorResult.put("status", "error");
            errorResult.put("message", e.getMessage());
            return errorResult.toString();
        }
    }
} 