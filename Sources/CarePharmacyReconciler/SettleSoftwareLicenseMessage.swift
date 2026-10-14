import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleSoftwareLicenseMessage keeps of each PeekSoftwareLicense response.
struct SettleSoftwareLicenseMessageRecord {
    var message: String
    var currencyCode: String
    var status: String
    var correlationID: String
}

/// Hands records to acme.payments.v1.PaymentCalculationService.
struct SettleSoftwareLicenseMessagePaymentCalculation {
    let client: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>

    func send(_ rec: SettleSoftwareLicenseMessageRecord) async throws {
        _ = try await client.getPaymentRates(.with {
            $0.paymentID = rec.status
        })
    }
}

/// Reads acme.licensing.v1.SoftwareLicenseQueryService/PeekSoftwareLicense and hands what it keeps to acme.payments.v1.PaymentCalculationService.
enum SettleSoftwareLicenseMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Licensing_V1_SoftwareLicenseQueryService.Client(wrapping: mesh)
        let found = try await upstream.peekSoftwareLicense(.with { $0.softwareLicenseID = "current-settle-software-license-message" })
        let rec = SettleSoftwareLicenseMessageRecord(
            message: found.result.message,
            currencyCode: found.softwareLicense.currencyCode,
            status: found.result.status,
            correlationID: found.result.correlationID
        )
        try await SettleSoftwareLicenseMessagePaymentCalculation(client: Acme_Payments_V1_PaymentCalculationService.Client(wrapping: mesh)).send(rec)
    }
}
