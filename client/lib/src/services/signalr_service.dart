import 'dart:async';

import 'package:client/src/config/http_config.dart';
import 'package:client/src/config/storage_config.dart';
import 'package:client/src/models/message.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';

class SignalrServiceException implements Exception {
  final String message;

  const SignalrServiceException(this.message);

  @override
  String toString() => message;
}

class SignalrService {
  HubConnection? _connection;
  Future<void>? _connecting;
  bool _handlersRegistered = false;
  bool _disposed = false;
  final Set<String> _joinedChats = {};
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();

  Stream<Message> get messages => _messageController.stream;

  void _handleReceiveMessage(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty || arguments.first is! Map) {
      return;
    }

    try {
      final payload = Map<String, dynamic>.from(arguments.first as Map);
      _messageController.add(Message.fromJson(payload));
    } on FormatException {
      // Ignore malformed payloads so one bad event does not break the stream.
    } on TypeError {
      // Ignore payloads that cannot be converted to the expected JSON shape.
    }
  }

  Future<void> connect() async {
    if (_disposed) {
      throw const SignalrServiceException('The chat connection is closed.');
    }
    if (_connection?.state == HubConnectionState.Connected) return;
    final connecting = _connecting;
    if (connecting != null) return connecting;

    final startFuture = _startConnection();
    _connecting = startFuture;
    try {
      await startFuture;
    } finally {
      if (identical(_connecting, startFuture)) _connecting = null;
    }
  }

  Future<void> _startConnection() async {
    final token = await secureStorage.read(key: 'token');
    if (token == null || token.isEmpty) {
      throw const SignalrServiceException('You are not authenticated.');
    }

    final connection = _connection ??= HubConnectionBuilder()
        .withUrl(
          ApiRoutes.baseSignalrUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async =>
                await secureStorage.read(key: 'token') ?? token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    if (!_handlersRegistered) {
      connection.on('ReceiveMessage', _handleReceiveMessage);
      connection.onreconnected(({connectionId}) {
        unawaited(_restoreJoinedChats());
      });
      _handlersRegistered = true;
    }

    if (connection.state == HubConnectionState.Disconnected) {
      await connection.start();
    } else if (connection.state == HubConnectionState.Connecting ||
        connection.state == HubConnectionState.Reconnecting) {
      final state = await connection.stateStream.firstWhere(
        (state) =>
            state == HubConnectionState.Connected ||
            state == HubConnectionState.Disconnected,
      );
      if (state != HubConnectionState.Connected) {
        throw const SignalrServiceException('Could not connect to chat.');
      }
    }
    await _rejoinChats();
  }

  Future<void> _rejoinChats() async {
    final connection = _connection;
    if (connection?.state != HubConnectionState.Connected) return;

    for (final chatId in _joinedChats.toList()) {
      await connection!.invoke('JoinChat', args: [chatId]);
    }
  }

  Future<void> _restoreJoinedChats() async {
    try {
      await _rejoinChats();
    } catch (_) {
      // A reconnect can succeed before authorization or network state settles.
    }
  }

  Future<void> joinChat(String chatId) async {
    if (_disposed) return;
    await connect();
    if (_disposed) return;
    if (_joinedChats.contains(chatId)) return;
    await _connection!.invoke('JoinChat', args: [chatId]);
    _joinedChats.add(chatId);
  }

  Future<void> leaveChat(String chatId) async {
    final connection = _connection;
    if (connection?.state == HubConnectionState.Connected &&
        _joinedChats.contains(chatId)) {
      await connection!.invoke('LeaveChat', args: [chatId]);
    }
    _joinedChats.remove(chatId);
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (_disposed) {
      throw const SignalrServiceException('The chat connection is closed.');
    }
    await connect();
    if (_disposed) {
      throw const SignalrServiceException('The chat connection is closed.');
    }
    if (!_joinedChats.contains(chatId)) await joinChat(chatId);
    await _connection!.invoke('SendMessage', args: [chatId, content]);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _joinedChats.clear();
    final connecting = _connecting;
    if (connecting != null) {
      try {
        await connecting;
      } catch (_) {
        // The connection is being disposed, so a failed startup is expected.
      }
    }
    final connection = _connection;
    _connection = null;
    try {
      if (connection != null &&
          connection.state != HubConnectionState.Disconnected) {
        await connection.stop();
      }
    } finally {
      await _messageController.close();
    }
  }
}
