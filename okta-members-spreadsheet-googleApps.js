/*
#****************************************************************************
#
#             Date:  26-May-2022
#
#****************************************************************************
# DESCRIPTION   : ***********************************************************
#                 This spreadsheet is meant to collect contractor information
#                 from Okta and getting contacts for them and their managers.
#
# REQUIREMENTS  : ***********************************************************
#                 Google Sheets
#                 JavaScript
#                 SpreadSheet setup as expected (permissions, columns, etc.)
#                 Read-only access token for Okta
#
# CODE REFERENCE: ***********************************************************
#                 https://support.okta.com/help/s/article/How-to-use-Okta-APIs-to-list-users-in-a-group?language=en_US
#                 https://developer.okta.com/docs/reference/api/users/#default-profile-properties
#                 https://developer.okta.com/docs/reference/core-okta-api/#link-header
#                 https://developer.okta.com/docs/reference/rate-limits/
#                 https://developer.okta.com/docs/reference/rl-global-mgmt/
#
#                 https://developers.google.com/apps-script/reference/url-fetch/http-response
#                 https://developers.google.com/apps-script/guides/services/quotas
#                 https://developers.google.com/sheets/api/limits
#
#                 https://www.matteoagosti.com/blog/2013/01/22/rate-limiting-function-calls-in-javascript/
#****************************************************************************
*/

const roadmin = "<read only admin token>";
const groupUrl = "<okta group url>";

const checkKey = (obj, keyName) => {
    if (Object.keys(obj).indexOf(keyName) !== -1) {
        return true;
    } else {
        return false;
    }
};

const parseManager = (managerDn) => {
    // TODO: What about same name managers?
    //example string "CN=First Last,OU=Users,OU=Sunnyvale,DC=am,DC=trimblecorp,DC=net";
    var strArray = managerDn.split(",")[0].split("=");
    return strArray[1];
}

var usersDataset = [];

/**
 * getGroup - Search Groups by name and get group id
 * for "Contractors (E-Tools)", then list group members
 * @return {JSON http response}
 */
function testGetGroup() {
    getGroup(groupUrl); //for testing in Google Apps Script development
}
function getGroup(groupUrl) {
    var headers = {
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'SSWS ' + roadmin
    }
    var options = {
        'method': 'get',
        'headers': headers
    }
    regex = /\<(.*)\>; (rel="next")/gm;
    Logger.info(groupUrl);
    var response = UrlFetchApp.fetch(groupUrl, options);
    usersDataset.push(...JSON.parse(response));
    var pagingLink = response.getHeaders().Link;
    var matchArray = regex.exec(pagingLink);
    if (matchArray == null) {
        Logger.info("User Count: " + usersDataset.length);
        return usersDataset;
    } else {
        groupUrl = matchArray[1];
        return getGroup(groupUrl);
    }
}


/**
 * getUserByName
 * @return {JSON http response}
 */
function getUserByName(firstName, lastName) {
    var headers = {
        'accept': 'application/json',
        'content-type': 'application/json',
        'authorization': 'SSWS ' + roadmin
    }
    var options = {
        'method': 'get',
        'headers': headers
    }
    var user_search = 'profile.firstName sw "' + firstName + '" and profile.lastName eq "' + lastName + '"';
    var userSearch = encodeURI(user_search);
    var response = UrlFetchApp.fetch("https://OKTA_URL_HERE/api/v1/users?search=" + userSearch, options);
    return JSON.parse(response);
}


/**
 * populateSpreadSheet - put retrieved group data into the Spreadsheet
 * @param {httpResponse} Expected data
 * @return {void}
 */
function populateSpreadSheet() {
    httpResponse = getGroup(groupUrl);
    var sheet = SpreadsheetApp.getActiveSheet();
    var lastRow = Math.max(sheet.getLastRow(), 1);
    sheet.insertRowAfter(lastRow);
    var timestamp = new Date();
    //columns map timestamp,contractor_email,status,department,manager,manager_email,department
    for (let i = 0; i < httpResponse.length; i++) {
        sheet.getRange(lastRow + 1 + i, 1).setValue(timestamp);
        sheet.getRange(lastRow + 1 + i, 2).setValue(httpResponse[i].profile.email);
        sheet.getRange(lastRow + 1 + i, 3).setValue(httpResponse[i].status);

        try {
            sheet.getRange(lastRow + 1 + i, 4).setValue(httpResponse[i].profile.department);
        } catch (error) {
            sheet.getRange(lastRow + 1 + i, 4).setValue("No department");
        }

        var managerDn = checkKey(httpResponse[i].profile, "managerDn");
        if (managerDn) {
            var manager = parseManager(httpResponse[i].profile.managerDn);
            theName = manager.split(" ");
            //Compound Manager Query
            theManager = getUserByName(theName[0], theName[theName.length - 1]);
            sheet.getRange(lastRow + 1 + i, 5).setValue(manager);
            try {
                sheet.getRange(lastRow + 1 + i, 6).setValue(theManager[0].profile.email);
                sheet.getRange(lastRow + 1 + i, 7).setValue(theManager[0].profile.department);
            } catch (error) {
                sheet.getRange(lastRow + 1 + i, 6).setValue("ERROR: " + error);
            }
        } else {
            sheet.getRange(lastRow + 1 + i, 5).setValue("No managerDn");
            sheet.getRange(lastRow + 1 + i, 6).setValue("No manager email");
            sheet.getRange(lastRow + 1 + i, 7).setValue("No manager department");
        }
    }
    SpreadsheetApp.flush();
}