angularjs-expertalk
===================

Repository for all collateral for the Jun 2014 Expertalk on AngularJS

Steps to get the backend running
--------------------------------
- Make sure Gradle is installed and on the PATH
- Make sure JAVA_HOME is set correctly
- clone this repo
- go to the fifaworlcup sub-directory
- run gradle command 'gradle clean build jettyRun'. This will get the backend running on 8080.
- You should now be able to access the app on http://localhost:8080/fifaworldcup

How to follow the sequence of steps
-----------------------------------

The talk was organised in the form of iteratively improving the app implementation. We start at step-00 where we have the basic app working using most common AngularJS constructs and features. We then go on step by step up to the final step-08, and in doing so we cover some of the more advance AngularJS features, that we used in our client app build. Here are quick instructions to replay these steps yourself using this repo:

1.  Clone this repo, so you get a local copy
2.  Each step in the demo is saved in the repo in the form of a Git Tag, on the 'master' branch
3.  Use this commend to list all tags [git tag -l]
4.  Go to firts step/tag using this command [git checkout step-00]
5.  Restart the backend server using the steps above
6.  Clear all browser cache and cookies
7.  Refresh browser to see the app working as per the current step/tag
8.  Go to the next step/tag as per point 4 above, and repeat. 
