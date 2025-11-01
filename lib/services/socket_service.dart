import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;
  final String url = 'https://alertnow-wi0n.onrender.com';

  void initialize(
    String role,
    String? barangay,
    String? municipality,
    Function(Map<String, dynamic>) onNewAlert,
    Function(Map<String, dynamic>) onPnpRedirect,
    Function(Map<String, dynamic>) onUpdateDropdown,
  ) {
    socket = IO.io(url, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    socket.onConnect((_) {
      print('Socket connected');
      socket.emit('register_role', {
        'role': role,
        if (barangay != null) 'barangay': barangay.toLowerCase(),
        if (municipality != null) 'municipality': municipality.toLowerCase(),
      });
    });

    socket.on('new_alert', (data) => onNewAlert(data));
    socket.on('pnp_redirect_alert', (data) => onPnpRedirect(data));
    socket.on('update_barangay_dropdown', (data) => onUpdateDropdown(data));
    socket.onConnectError((data) => print('Connection error: $data'));
    socket.onDisconnect((_) => print('Socket disconnected'));
    socket.connect();
  }

  void emit(String event, dynamic data) {
    try {
      socket.emit(event, data);
    } catch (e) {
      print('Error emitting $event: $e');
    }
  }

  void disconnect() => socket.disconnect();
}