function Game(name, visitor, visitorScore, home, homeScore) {
    this.name = name;
    this.visitor = visitor;
    this.visitorScore = visitorScore;
    this.home = home;
    this.homeScore = homeScore;
}

Game.prototype.isDone = function() {
    return (this.visitorScore.length > 0 && this.homeScore.length > 0);
}

Game.prototype.winner = function() {
    if (this.isDone() && (this.visitorScore > this.homeScore)) {
        return this.visitor;
    } else if (this.isDone() && (this.homeScore > this.visitorScore)) {
        return this.home;
    }
}

function parseCSV(text) {
    var allLines = text.split(/\r\n|\n/);
    var headers = allLines[0].split(',');
    var lines = [];

    for (var i = 1; i < allLines.length; i++) {
        if ($.trim(allLines[i]).length == 0) {
            continue;
        } else {
            var data = allLines[i].split(',');
            lines.push(new Game(data[1], data[3], data[4], data[5], data[6]));
        }
    }

    console.log("Found: " + lines.length + " games");
    return lines;
}

function Participant(name) {
    this.name = name;
    this.wins = 0;
    this.losses = 0;
    this.pointsFor = 0;
    this.pointsLost = 0;
    this.place = -1;
}

Participant.prototype.won = function(points) {
    this.wins++;
    this.pointsFor += points;
};

Participant.prototype.lost = function(points) {
    this.losses++;
    this.pointsLost += points;
};

Participant.prototype.setPlace = function(place) {
    this.place = place;
};

Participant.prototype.pointsRemaining = function() {
    // assumes 40 games
    return (820 - (this.pointsFor + this.pointsLost));
};

Participant.prototype.isFamilyOrFriend = function() {
    var people = ["Ribwich", "0 Illini GW", "0 Illini Mike", "Red Rhody", "Chuck", "Miss Scarlet", "teamocil"];
    return (people.indexOf(this.name) != -1);
}

function loadResults(handlerFunc) {
    var threshold = 15 * 60 * 1000; // 15 minutes in milliseconds
    var lastUpdated = JSON.parse(localStorage.getItem("gameResultsUpdatedAt"));
    var age = (lastUpdated != null) ? new Date() - new Date(lastUpdated) : threshold;

    if (age >= threshold) {
        console.log("Fetching game results, lastUpdated = " + lastUpdated);
        $.ajax({
            type: "GET",
            url: "https://dl.dropboxusercontent.com/u/18038003/cfb_results_2016.csv",
            dataType: "text",
            success: function(data) {
                var results = parseCSV(data);
                localStorage.setItem("gameResults", JSON.stringify(results));
                localStorage.setItem("gameResultsUpdatedAt", JSON.stringify(new Date()));
                handleResults(results, handlerFunc);
            }
        });
    } else {
        console.log("Using stored game results, lastUpdated = " + lastUpdated);
        var results = $.map(JSON.parse(localStorage.getItem("gameResults")), function(data) {
            return new Game(data.name, data.visitor, data.visitorScore, data.home, data.homeScore);
        });
        handleResults(results, handlerFunc);
    }
}

function handleResults(results, renderFunc) {
    $.getJSON('https://s3.amazonaws.com/danhodge-cfb/2016/participants_2016.json', function(participants) {
        renderFunc(results, participants);
    });
}

function handleParticipants(results, participants) {
    var winners = new Object();
    $.each(results, function(index, value) {
        if (value.isDone()) {
            console.log("Setting winner: " + value.name + " = " + value.winner());
            winners[value.name] = value.winner();
        }
    });
    console.log("winners = " + Object.keys(winners));

    var scores = $.map(participants, function(participant, index) {
        user = new Participant(participant.name);
        $.map(participant.picks, function(pick) {
            $.each(winners, function(game, winner) {
                if (pick.game_name == game && pick.team_name == winner) {
                    user.won(pick.points);
                } else if (pick.game_name == game && pick.team_name != winner) {
                    user.lost(pick.points);
                }
            });
        });
        return user;
    });

    var topScores = scores.sort(function(a, b) {
        if (a.pointsFor > b.pointsFor) {
            return -1;
        } else if (a.pointsFor < b.pointsFor) {
            return 1;
        } else {
            if (a.pointsLost < b.pointsLost) {
                return -1;
            } else if (a.pointsLost > b.pointsLost) {
                return 1;
            } else {
                return 0;
            }
        }
    });

    var filteredScores = $.grep(topScores, function(participant, index) {
        participant.setPlace(index + 1);
        return true;
    });

    html = new Array();
    $.each(filteredScores, function(index, value) {
        html.push("<tr>");
        html.push("<td>" + value.place + "</td>");

        if (value.isFamilyOrFriend() == true) {
            html.push("<td><a class='fam-friend' href='participant.html?name=" + value.name + "'>" + value.name + "</a></td>");
        } else {
            html.push("<td><a href='participant.html?name=" + value.name + "'>" + value.name + "</a></td>");
        }

        html.push("<td>" + value.wins + "</td>");
        html.push("<td>" + value.losses + "</td>");
        html.push("<td>" + value.pointsFor + "</td>");
        html.push("<td>" + value.pointsLost + "</td>");
        html.push("<td>" + value.pointsRemaining() + "</td>");
        html.push("</tr>");
    });
    $('#standings tbody').html(html.join(''));
}

function GameResult(name, winner) {
    this.name = name;
    this.winner = winner;
    this.points = 0;
    this.choice = null;
}

GameResult.prototype.chosen = function(team, points) {
    this.choice = team;
    this.points = points;
}

GameResult.prototype.winnerName = function() {
    return (this.isDone()) ? this.winner : "";
}

GameResult.prototype.choiceInfo = function() {
    return (this.isDone()) ? this.choice : this.choice + " (" + this.points + ")";
}

GameResult.prototype.isDone = function() {
    return (this.winner != null);
}

GameResult.prototype.didWin = function() {
    return (this.isDone() && this.winner == this.choice);
}

GameResult.prototype.didLose = function() {
    return (this.isDone() && this.winner != this.choice);
}

GameResult.prototype.pointsFor = function() {
    if (this.didWin()) {
        return this.points;
    } else if (this.didLose()) {
        return 0;
    } else {
        return "";
    }
}

GameResult.prototype.pointsLost = function() {
    if (this.didLose()) {
        return this.points;
    } else if (this.didWin()) {
        return 0;
    } else {
        return "";
    }
}

function handleParticipant(results, participants) {
    var winners = new Object();
    $.each(results, function(index, value) {
        if (value.isDone()) {
            console.log("Setting winner: " + value.name + " = " + value.winner());
            winners[value.name] = value.winner();
        }
    });
    console.log("winners = " + Object.keys(winners));

    var params = [location.search.split("?")[1].split("=")];
    var selected = $.grep(params, function(param, index) {
        return (param[0] == "name");
    });
    var decoded = decodeURI(selected[0][1]);
    var participant = $.grep(participants, function(person, index) {
        return (person.name == decoded);
    });

    var games = $.map(results, function(result) {
        game = new GameResult(result.name, result.winner());
        $.each(participant[0].picks, function(index, pick) {
            if (pick.game_name == game.name) {
                console.log("choice: " + pick.team_name);
                game.chosen(pick.team_name, pick.points);
            }
        });
        return game;
    });

    html = new Array();
    html.push("<thead>");
    html.push("<tr>");
    html.push("<th>Game</th>");
    html.push("<th>Pick</th>");
    html.push("<th>Winner</th>");
    html.push("<th>Points Correct</th>");
    html.push("<th>Points Incorrect</th>");
    html.push("</tr>");
    html.push("</thead>");

    var pointsFor = 0;
    var pointsLost = 0;

    html.push("<tbody>");
    $.each(games, function(index, value) {
        var style = "incomplete";
        if (value.didWin()) {
            style = "won";
        } else if (value.didLose()) {
            style = "lost";
        }
        html.push("<tr>");
        var gameStyle = (style == "incomplete") ? " class='incomplete'" : "";
        html.push("<td" + gameStyle+ ">" + value.name + "</td>");
        html.push("<td class='" + style + "'>" + value.choiceInfo() + "</td>");
        html.push("<td>" + value.winnerName() + "</td>");
        html.push("<td>" + value.pointsFor() + "</td>");
        html.push("<td>" + value.pointsLost() + "</td>");
        html.push("</tr>");
        if (value.isDone()) {
            pointsFor += value.pointsFor();
            pointsLost += value.pointsLost();
        }
    });

    html.push("<tr>");
    html.push("<td colspan='3'></td>");
    html.push("<td>" + pointsFor + "</td>");
    html.push("<td>" + pointsLost + "</td>");
    html.push("</tr>");
    html.push("</tbody>");
    $('#games').html(html.join(''));
}
