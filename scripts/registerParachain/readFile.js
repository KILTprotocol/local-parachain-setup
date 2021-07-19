const fs = require('fs');

// Read file from path.
async function readFileFromPath(path) {
    return fs.readFileSync(path, (data, err) => {
        if (err) {
            console.error(err);
        }
        if (data) {
            return data.toString();
        }
        return '';
    });
}
module.exports.readFileFromPath = readFileFromPath;