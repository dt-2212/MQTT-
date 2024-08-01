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
      appBar: AppBar(title: Text('Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Enter your year of birth for verification'),
            TextField(
              controller: _yearOfBirthController,
              decoration: InputDecoration(labelText: 'Year of Birth'),
            ),
            ElevatedButton(
              onPressed: _verifyYearOfBirth,
              child: Text('Verify'),
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
        'User ${widget.username} year of birth verification ${success ? 'successful' : 'failed'}');
    if (builder.payload != null) {
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void _showDialog(bool success) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(success ? 'Successful' : 'failed'),
            content: Text(success
                ? 'You have successfully verified your year of birth.'
                : 'Verification failed. Please try again.'),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (success) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Done'))
            ],
          );
        });
  }
}
