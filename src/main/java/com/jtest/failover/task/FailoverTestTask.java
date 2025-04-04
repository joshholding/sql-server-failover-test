package com.jtest.failover.task;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.jtest.failover.service.DbService;

@Component
@EnableScheduling
public class FailoverTestTask {
  private static final Logger logger = LoggerFactory.getLogger( FailoverTestTask.class );

  @Autowired private DbService dbService;

  @Scheduled(fixedRate = 5000) 
  public void runTask() {
    try {
      var result = dbService.getDbServername();
      logger.info( result.toString() );    
    } catch (Exception e) {
      logger.error( e.getLocalizedMessage() ); 
    }
  }
}
