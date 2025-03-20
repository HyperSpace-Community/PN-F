const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

// Device Schema
const deviceSchema = new mongoose.Schema({
  deviceToken: { type: String, unique: true },
  deviceInfo: Object,
  lastSeen: { type: Date, default: Date.now }
});

const Device = mongoose.model('Device', deviceSchema);

// Register device
app.post('/register', async (req, res) => {
  try {
    const { deviceToken, deviceInfo } = req.body;
    await Device.findOneAndUpdate(
      { deviceToken },
      { deviceToken, deviceInfo, lastSeen: new Date() },
      { upsert: true }
    );
    const devices = await Device.find({}, 'deviceToken');
    res.json({ status: 'success', activeDevices: devices.map(d => d.deviceToken) });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send notification
app.post('/send-notification', async (req, res) => {
  try {
    const { targetToken, senderToken, title, body } = req.body;
    const targetDevice = await Device.findOne({ deviceToken: targetToken });
    
    if (!targetDevice) {
      return res.status(404).json({ error: 'Target device not found' });
    }
    
    // Here you would implement your actual notification sending logic
    console.log(`Sending notification to ${targetToken} from ${senderToken}`);
    
    res.json({ status: 'success', message: 'Notification sent' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Connect to MongoDB
mongoose.connect('mongodb://localhost/push_notifications', {
  useNewUrlParser: true,
  useUnifiedTopology: true
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
