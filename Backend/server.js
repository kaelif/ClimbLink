const express = require('express');
const cors = require('cors');
const partnersStack = require('./src/data/partners');

const app = express();

app.use(cors());

app.get("/getStack", (req, res) => {
    res.json({
        stack: partnersStack,
        count: partnersStack.length,
    });
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});