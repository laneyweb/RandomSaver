function loadWords() {
    var filePath = "/home/darren/Work/RandomSaver/words.txt"
    var file = new File(filePath)
    if (!file.exists()) {
        return ["hello", "world", "omarchy", "random", "screensaver"]
    }
    var content = file.read()
    var lines = content.split("\n")
    var words = []
    for (var i = 0; i < lines.length; i++) {
        var w = lines[i].trim()
        if (w !== "") words.push(w)
    }
    return words.length > 0 ? words : ["hello"]
}

function saveWords(words) {
    var filePath = "/home/darren/Work/RandomSaver/words.txt"
    var content = words.join("\n") + "\n"
    var file = new File(filePath)
    file.write(content)
}

function convertWord(word) {
    var scriptPath = "/home/darren/Work/RandomSaver/scripts/convert.py"
    var outputPath = "/home/darren/.config/omarchy/branding/screensaver.txt"
    var cmd = ["python3", scriptPath, word, outputPath].join(" ")
    run(cmd)
}

function restoreDefault() {
    var cmd = "cp /home/darren/Work/RandomSaver/default-screensaver.txt /home/darren/.config/omarchy/branding/screensaver.txt"
    run(cmd)
}
