package com.equalexperts;

import org.apache.commons.io.IOUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ResourceLoader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

import javax.annotation.PostConstruct;
import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
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

    @RequestMapping("/")
    public ModelAndView home(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException {
        if (isReadyToPlay(request)) {
            return new ModelAndView("fifaworldcup.html");
        } else {
            response.sendRedirect("/fifaworldcup/readytoplay");
        }
        return null;
    }

    @RequestMapping("/readytoplay")
    public ModelAndView readyToPlay() {
        return new ModelAndView("ready-to-play.html");
    }

    @RequestMapping("/play")
    public void play(HttpServletResponse response) throws IOException, ServletException {
        response.addCookie(new Cookie("readyToPlay", "yes"));
        response.sendRedirect("/fifaworldcup");
    }

    @RequestMapping(value="/matches", method = GET, produces = "application/json")
    public String matches(HttpServletRequest request, HttpServletResponse response) throws IOException {
        pauseForRandomTime();
        if (!isLoggedIn(request)) {
            response.sendError(401);
        }
        return matchesJson;
    }

    @RequestMapping(value="/players", method = GET, produces = "application/json")
    public String players(HttpServletRequest request, HttpServletResponse response) throws IOException {
        pauseForRandomTime();
        if (!isLoggedIn(request)) {
            response.sendError(401);
        }
        return playersJson;
    }

    @RequestMapping(value="/teams", method = GET, produces = "application/json")
    public String teams(HttpServletRequest request, HttpServletResponse response) throws IOException {
        pauseForRandomTime();
        if (!isLoggedIn(request)) {
            response.sendError(401);
        }
        return teamsJson;
    }

    private boolean isReadyToPlay(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : request.getCookies()) {
                if ("readyToPlay".equals(cookie.getName()) && "yes".equals(cookie.getValue()))
                    return true;
            }
        }
        return false;
    }

    private boolean isLoggedIn(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if ("readyToPlay".equals(cookie.getName())) {
                    return true;
                }
            }
        }
        return false;
    }

    private void pauseForRandomTime() {
        try {
            Thread.sleep(20);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}