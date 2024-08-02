import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class VerificationScreen extends StatefulWidget {
  final String username;

  VerificationScreen({required this.username});

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

//==============================================================================
class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _yearOfBirthController = TextEditingController();
  late MqttServerClient client;
  final String topic = 'test/topic';
  late String messMQTT = 'No message';

  @override
  void initState() {
    super.initState();
    _setupMQTT();
  }

  void _setupMQTT() {
    client = MqttServerClient('broker.emqx.io', '1883');
    client.logging(on: true);
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.onSubscribeFail = _onSubscribeFail;
    client.onUnsubscribed = _onUnsubscribed;
    _connectMQTT();
  }

  Future<void> _connectMQTT() async {
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
    _subscribeToTopic();
  }

  void _subscribeToTopic() {
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates!.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? event) {
    final MqttPublishMessage recMess = event![0].payload as MqttPublishMessage;
    final String message =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print('Received message: $message from topic: ${event[0].topic}');
    setState(() {
      messMQTT = message;
    });
  }

//==============================================================================
  void _onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _onSubscribeFail(String topic) {
    print('Failed to subscribe to topic: $topic');
  }

  void _onUnsubscribed(String? topic) {
    print('Unsubscribed from topic: $topic');
  }

//==============================================================================
  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            const Text(
              'Enter your year of birth for verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold  ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearOfBirthController,
                    decoration:
                        const InputDecoration(labelText: 'Year of Birth'),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _verifyYearOfBirth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                  ),
                  child: const Text(
                    'Verify ',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            const Text(
              'Messages',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold ),
            ),
            Text(
              messMQTT,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

//==============================================================================
  void _verifyYearOfBirth() {
    String correctYearOfBirth = '2002';
    bool success = _yearOfBirthController.text == correctYearOfBirth;
    _sendVerificationResult(success);
    _showDialog(success);
  }

  void _sendVerificationResult(bool success) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(
        'User ${widget.username}: Year of birth verification ${success ? 'successful' : 'failed'}');
    if (builder.payload != null) {
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void _showDialog(bool success) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(success ? 'Successful' : 'failed'),
            content: Text(success
                ? 'Verification successfully.'
                : 'Verification failed. Please try again.'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (success) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Done'))
            ],
          );
        });
  }
//==============================================================================
}
