/*
 * JavaScript Pretty Date
 * Copyright (c) 2008 John Resig (jquery.com)
 * Licensed under the MIT license.
 */

// Takes an ISO time and returns a string representing how
// long ago the date represents.

function prettyDate(time) {
    var date = new Date(time || "");
    console.log('date: ' + date);
    var diff = (((new Date()).getTime() - date.getTime()) / 1000);
    console.log('diff: ' + diff);
    var day_diff = Math.floor(diff / 86400);
    console.log('daydiff: ' + day_diff);

    if (isNaN(day_diff) || day_diff < 0 || day_diff >= 31) {
      console.log('some shit went bad');
      return;
    }

    return day_diff == 0 && (
    diff < 60 && "just now" || diff < 120 && "1 minute ago" || diff < 3600 && Math.floor(diff / 60) + " minutes ago" || diff < 7200 && "1 hour ago" || diff < 86400 && Math.floor(diff / 3600) + " hours ago") || day_diff == 1 && "Yesterday" || day_diff < 7 && day_diff + " days ago" || day_diff < 31 && Math.ceil(day_diff / 7) + " weeks ago";
}
