import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Page principale de paiement permettant à l'utilisateur de saisir un montant
/// et d'initier une transaction
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  // Contrôleur pour le champ de saisie du montant
  final TextEditingController _amountController = TextEditingController();

  // État du chargement
  bool _isLoading = false;

  /// Fonction qui gère le processus de paiement
  /// - Envoie une requête POST à l'API
  /// - Affiche la page de paiement dans un modal si succès
  /// - Gère les erreurs avec des SnackBar
  Future<void> _processPayment() async {
    // Active l'état de chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // Appel à l'API de transaction
      final response = await http.post(
        Uri.parse('https://c511-41-138-98-104.ngrok-free.app/api/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': double.parse(_amountController.text),
        }),
      );

      // Décode la réponse JSON
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final paymentLink = responseData['data']['payment_link'];

        // Vérification si le widget est toujours monté
        if (!mounted) return;

        // Affichage du modal avec la WebView
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => PaymentWebView(paymentLink: paymentLink),
        );
      } else {
        if (!mounted) return;
        // Affiche le message d'erreur retourné par l'API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ??
                'Erreur lors du traitement du paiement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Affiche l'erreur technique avec plus de détails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(
              seconds: 5), // Plus long pour les erreurs techniques
        ),
      );
    } finally {
      // Désactive l'état de chargement si le widget est toujours monté
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Champ de saisie du montant
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 20),
            // Bouton de paiement avec indicateur de chargement
            ElevatedButton(
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Payer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget qui affiche la page de paiement dans une WebView
/// Utilisé dans un modal bottom sheet
class PaymentWebView extends StatelessWidget {
  final String paymentLink;

  const PaymentWebView({super.key, required this.paymentLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Hauteur du modal fixée à 90% de l'écran
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Barre supérieure avec bouton de fermeture
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // WebView pour afficher la page de paiement
          Expanded(
            child: WebViewWidget(
              controller: WebViewController()
                ..loadRequest(Uri.parse(paymentLink))
                ..setJavaScriptMode(JavaScriptMode.unrestricted),
            ),
          ),
        ],
      ),
    );
  }
}
