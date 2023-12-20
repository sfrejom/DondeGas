import PassKit

class PaymentManager: NSObject {
    static let shared = PaymentManager()
    var paymentAuthorizationCompletion: ((PKPaymentAuthorizationResult) -> Void)?

    func startPayment(completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        self.paymentAuthorizationCompletion = completion

        guard PKPaymentAuthorizationViewController.canMakePayments() else {
            print("Apple Pay no está disponible")
            return
        }

        let request = PKPaymentRequest()
        request.merchantIdentifier = "<merchant_id>"
        request.supportedNetworks = [.visa, .masterCard, .amex]
        request.merchantCapabilities = [.threeDSecure]
        request.countryCode = "ES"
        request.currencyCode = "EUR"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Café para el desarrollador", amount: NSDecimalNumber(string: "3.00"))
        ]


        if let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) {
            paymentVC.delegate = self
            // Presentar el controlador de vista de pago desde la vista actual
        } else {
            print("No se pudo crear el controlador de vista de pago")
        }
    }
}

extension PaymentManager: PKPaymentAuthorizationViewControllerDelegate {
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true)
    }

    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Manejar la autorización del pago
        paymentAuthorizationCompletion?(.init(status: .success, errors: nil))
        // Aquí puedes enviar el token de pago a tu servidor
    }
}
