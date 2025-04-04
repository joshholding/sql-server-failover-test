# SQL Server JDBC Driver Failover Test of loginTimeout
Basic [Spring Boot](https://github.com/spring-projects/spring-boot) app starts a Task that executes and logs the results of `@@SERVERNAME` every 5 seconds. 

Used to test [Microsoft JDBC Driver for SQL Server](https://github.com/microsoft/mssql-jdbc) during a server failover with SQL Server 2022. Starting with JDBC Driver version [12.8.1](https://learn.microsoft.com/en-us/sql/connect/jdbc/release-notes-for-the-jdbc-driver?view=sql-server-ver16#128), if the [loginTimeout](https://learn.microsoft.com/en-us/sql/connect/jdbc/understand-timeouts?view=sql-server-ver16) jdbc property has shorter values, failovers do not succeed for the application.

## Test Steps


1. Configure and setup SQL Server for [mirroring with High Safety](https://learn.microsoft.com/en-us/sql/database-engine/database-mirroring/database-mirroring-sql-server?view=sql-server-ver16).
-  With or without automatic failover (with or without a witness). Issue is found in either scenario. 
- Only tested with SQL Server 2022.
- DB Mirroing setup details out of scope, but for reference, basic SQL used can be found [here](./src/main/resources/db/db-setup.sql). 

2. Modify [pom.xml](./pom.xml) for the version to test
```xml
    <dependency>
      <groupId>com.microsoft.sqlserver</groupId>
      <artifactId>mssql-jdbc</artifactId>
      <!--OK <version>12.2.0.jre11</version>-->
      <!--OK <version>12.6.4.jre11</version>-->
      <!--FAIL <version>12.8.1.jre11</version>-->
      <!--FAIL <version>12.10.0.jre11</version>-->
      <version>12.10.0.jre11</version>
      <scope>runtime</scope>
    </dependency>
```

3. Modify [application.properties](./src/main/resources/application.properties) for the loginTimeout value to test
```properties
# ok
#spring.datasource.url=jdbc:sqlserver://sql_principal:1433;databaseName=jtest;failoverPartner=sql_mirror;trustServerCertificate=true;encrypt=true; 
#spring.datasource.url=jdbc:sqlserver://sql_principal:1433;databaseName=jtest;failoverPartner=sql_mirror;trustServerCertificate=true;encrypt=true;loginTimeout=15
#spring.datasource.url=jdbc:sqlserver://sql_principal:1433;databaseName=jtest;failoverPartner=sql_mirror;trustServerCertificate=true;encrypt=true;loginTimeout=30;  
#spring.datasource.url=jdbc:sqlserver://sql_principal:1433;databaseName=jtest;failoverPartner=sql_mirror;trustServerCertificate=true;encrypt=true;loginTimeout=60;

# fails for v12.8.1.jre11 and above, ok for v12.6.4.jre11 and below
spring.datasource.url=jdbc:sqlserver://sql_principal:1433;databaseName=jtest;failoverPartner=sql_mirror;trustServerCertificate=true;encrypt=true;loginTimeout=5;
#spring.datasource.url=jdbc:sqlserver://sql_principal:1433;databaseName=jtest;failoverPartner=sql_mirror;trustServerCertificate=true;encrypt=true;loginTimeout=10;
```

4. Start the app
```bash
sql-server-failover-test$ ./mvnw spring-boot:run
```

5. Execute this SQL on the principal:
```SQL
ALTER DATABASE jtest SET PARTNER FAILOVER
```
-  and observe the jdbc connection behavior in the log output:
    - **SUCCESS**: Expected output when failover succeeds
    ```log
    2025-04-04 18:15:04.966 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_principal}]
    2025-04-04 18:15:09.963 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_principal}]
    2025-04-04 18:15:14.949 WARN  [c.z.h.pool.PoolBase] - HikariPool-1 - Failed to validate connection ConnectionID:3 ClientConnectionId: 1510cf9b-716f-4b00-98e6-b92b5329604a (The connection is closed.). Possibly consider using a shorter maxLifetime value.
    2025-04-04 18:15:20.122 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_mirror}]
    2025-04-04 18:15:20.131 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_mirror}]
    2025-04-04 18:15:24.886 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_mirror}]
    ```

    - **FAILURE**: Output when failover does not occur
    ```log
    2025-04-04 18:17:23.918 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_principal}]
    2025-04-04 18:17:28.921 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_principal}]
    2025-04-04 18:17:33.917 INFO  [c.j.f.t.FailoverTestTask] - [{ServerName=sql_principal}]
    2025-04-04 18:17:38.904 WARN  [c.z.h.pool.PoolBase] - HikariPool-1 - Failed to validate connection ConnectionID:1 ClientConnectionId: 29f34790-0c6a-4dec-a06b-bd39a65b0e03 (The connection is closed.). Possibly consider using a shorter maxLifetime value.
    ...
    2025-04-04 18:18:08.883 ERROR [c.j.f.t.FailoverTestTask] - Failed to obtain JDBC Connection
    2025-04-04 18:18:38.861 ERROR [c.j.f.t.FailoverTestTask] - Failed to obtain JDBC Connection
    2025-04-04 18:19:08.840 ERROR [c.j.f.t.FailoverTestTask] - Failed to obtain JDBC Connection
    ```

## Results

| JDBC Version | properties | Failover Result |
| ------------ | ---------- | --------------- |
| 12.6.4.jre11 | loginTimeout=5 | OK |
| 12.6.4.jre11 | loginTimeout=10 | OK |
| 12.6.4.jre11 | loginTimeout=15 | OK |
| 12.6.4.jre11 | loginTimeout=30 | OK |
| |
| 12.8.1.jre11 | loginTimeout=5 | **FAIL** |
| 12.8.1.jre11 | loginTimeout=10 | **FAIL** |
| 12.8.1.jre11 | loginTimeout=15 | OK |
| 12.8.1.jre11 | loginTimeout=30 | OK |
| |
| 12.10.0.jre11 | loginTimeout=5 | **FAIL** |
| 12.10.0.jre11 | loginTimeout=10 | **FAIL** |
| 12.10.0.jre11 | loginTimeout=15 | OK |
| 12.10.0.jre11 | loginTimeout=30 | OK |
