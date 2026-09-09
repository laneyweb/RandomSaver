.pragma library

// Pure helpers for RandomSaver Panel.qml. No File/Process access here —
// file IO lives in a FileView and execution in a Process (Quickshell.Io).

function defaultWords() {
    return ["hello", "world", "omarchy", "random", "screensaver"];
}

function parseWords(content) {
    var lines = String(content || "").split("\n");
    var words = [];
    for (var i = 0; i < lines.length; i++) {
        var w = lines[i].trim();
        if (w !== "")
            words.push(w);
    }
    return words.length > 0 ? words : defaultWords();
}

function serializeWords(words) {
    return words.join("\n") + "\n";
}

function pickRandom(words) {
    if (!words || words.length === 0)
        return defaultWords()[0];
    return words[Math.floor(Math.random() * words.length)];
}
