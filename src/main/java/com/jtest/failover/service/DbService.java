package com.jtest.failover.service;

import java.util.List;
import java.util.Map;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

@Service
public class DbService {
  private static final Logger logger = LoggerFactory.getLogger(DbService.class);
  private final JdbcTemplate jdbcTemplate;

  @Autowired
  public DbService(DataSource dataSource) {
    this.jdbcTemplate = new JdbcTemplate(dataSource);
  }

  public List<Map<String, Object>> getDbServername() {
    // String sql = "select @@SERVERNAME [ServerName], getdate() [Datetime]";
    String sql = "select @@SERVERNAME [ServerName]";
    logger.trace("Executing SQL query: {}", sql);
    List<Map<String, Object>> results = jdbcTemplate.queryForList(sql);
    return results;
  }
}
