import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TournamentCodeGenerator(),
    );
  }
}

class TournamentCodeGenerator extends StatefulWidget {
  const TournamentCodeGenerator({Key? key}) : super(key: key);

  @override
  _TournamentCodeGeneratorState createState() =>
      _TournamentCodeGeneratorState();
}

class _TournamentCodeGeneratorState extends State<TournamentCodeGenerator> {
  final String apiKey = "TU_API_KEY";
  final String providerRegion = "LAN";
  String? tournamentCode;
  bool isLoading = false;

  Future<void> createTournamentCode() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Crear un proveedor
      final providerResponse = await http.post(
        Uri.parse(
            "https://americas.api.riotgames.com/lol/tournament/v5/providers"),
        headers: {
          "X-Riot-Token": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "region": providerRegion,
          "url": "https://example.com/callback",
        }),
      );

      if (providerResponse.statusCode != 200) {
        throw Exception(
            "Error al crear proveedor: ${providerResponse.statusCode}");
      }

      final providerId = jsonDecode(providerResponse.body);

      // Crear un torneo
      final tournamentResponse = await http.post(
        Uri.parse(
            "https://americas.api.riotgames.com/lol/tournament/v5/tournaments"),
        headers: {
          "X-Riot-Token": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "name": "Torneo Flutter",
          "providerId": providerId,
        }),
      );

      if (tournamentResponse.statusCode != 200) {
        throw Exception(
            "Error al crear torneo: ${tournamentResponse.statusCode}");
      }

      final tournamentId = jsonDecode(tournamentResponse.body);

      // Generar código de torneo
      final codeResponse = await http.post(
        Uri.parse("https://americas.api.riotgames.com/lol/tournament/v5/codes"),
        headers: {
          "X-Riot-Token": apiKey,
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "count": 1, // Genera 1 código
          "tournamentId": tournamentId,
          "mapType": "SUMMONERS_RIFT",
          "pickType": "DRAFT_MODE",
          "spectatorType": "ALL",
          "teamSize": 5,
          "metadata": "Torneo generado desde Flutter",
        }),
      );

      if (codeResponse.statusCode != 200) {
        throw Exception(
            "Error al generar código de torneo: ${codeResponse.statusCode}");
      }

      final codes = jsonDecode(codeResponse.body);
      setState(() {
        tournamentCode = codes[0];
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        tournamentCode = "Error al generar código.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generador de Torneo"),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Presiona el botón para generar un código de torneo.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: createTournamentCode,
                    child: const Text("Generar Código"),
                  ),
                  const SizedBox(height: 20),
                  if (tournamentCode != null)
                    Text(
                      tournamentCode!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
      ),
    );
  }
}
