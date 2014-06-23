package com.equalexperts;

import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ResourceLoader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import java.io.IOException;

import static org.springframework.web.bind.annotation.RequestMethod.GET;

/**
 * Created by avinash on 23/6/14.
 */
@RestController
public class FIFAWorldCupController {

    private String matchesJson;
    private String playersJson;
    private String teamsJson;

    @Autowired
    private ResourceLoader resourceLoader;

    @PostConstruct
    public void setup() throws IOException {
        matchesJson = IOUtils.toString(resourceLoader.getResource("classpath:matches.json").getInputStream());
        playersJson = IOUtils.toString(resourceLoader.getResource("classpath:players.json").getInputStream());
        teamsJson = IOUtils.toString(resourceLoader.getResource("classpath:teams.json").getInputStream());
    }

    @RequestMapping(value="/matches", method = GET, produces = "application/json")
    public String matches() {
        return matchesJson;
    }

    @RequestMapping(value="/players", method = GET, produces = "application/json")
    public String players() {
        return playersJson;
    }

    @RequestMapping(value="/teams", method = GET, produces = "application/json")
    public String teams() {
        return teamsJson;
    }
}