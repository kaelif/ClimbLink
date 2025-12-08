const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());

app.get("/getStack", (req, res) => {
    res.json({"users": ["userOne", "userTwo", "userThree"]});
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});