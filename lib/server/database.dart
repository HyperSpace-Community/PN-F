import 'device_model.dart';

class Database {
  static final Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

  final Map<String, Device> _devices = {};

  Future<void> registerDevice(Device device) async {
    _devices[device.deviceToken] = device;
  }

  Future<List<Device>> getActiveDevices() async {
    return _devices.values.toList();
  }

  Future<Device?> getDevice(String token) async {
    return _devices[token];
  }
}
