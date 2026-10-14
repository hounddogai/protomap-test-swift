import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayPaymentRatesNumber keeps of each GetPaymentRates response.
struct ReplayPaymentRatesNumberRecord {
    var number: String
    var message: String
    var notes: String
}

/// Where ReplayPaymentRatesNumber hands each record.
protocol ReplayPaymentRatesNumberSink {
    func apply(_ rec: ReplayPaymentRatesNumberRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionApprovalService.
struct ReplayPaymentRatesNumberPrescriptionApproval: ReplayPaymentRatesNumberSink {
    let client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>

    func apply(_ rec: ReplayPaymentRatesNumberRecord) async throws {
        _ = try await client.escalatePrescription(.with {
            $0.details.approverEmail = rec.message
            $0.prescription.prescriptionID = rec.notes
            $0.prescription.number = rec.number
        })
    }
}

/// Sends records to acme.search.v1.SearchIndexValidationService.
struct ReplayPaymentRatesNumberSearchIndexValidation: ReplayPaymentRatesNumberSink {
    let client: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>

    func apply(_ rec: ReplayPaymentRatesNumberRecord) async throws {
        _ = try await client.getSearchIndexRules(.with {
            $0.searchIndexID = rec.notes
        })
    }
}

/// Hands records to acme.patientapp.v1.PatientHomeService.
struct ReplayPaymentRatesNumberPatientHome: ReplayPaymentRatesNumberSink {
    let client: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>

    func apply(_ rec: ReplayPaymentRatesNumberRecord) async throws {
        _ = try await client.listPatientHomes(.with {
            $0.filter.query = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayPaymentRatesNumberLogOnly: ReplayPaymentRatesNumberSink {
    let logger = Logger(label: "acme.replay-payment-rates-number")

    func apply(_ rec: ReplayPaymentRatesNumberRecord) async throws {
        logger.info("No sink for record", metadata: ["number": .string(rec.number)])
    }
}

/// Reads acme.payments.v1.PaymentCalculationService/GetPaymentRates and hands what it keeps to the sink of its kind.
enum ReplayPaymentRatesNumber {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Payments_V1_PaymentCalculationService.Client(wrapping: mesh)
        let got = try await upstream.getPaymentRates(.with { $0.paymentID = "main-replay-payment-rates-number" })
        let record = ReplayPaymentRatesNumberRecord(
            number: got.payment.number,
            message: Kit.Text.normalize(got.result.message),
            notes: got.payment.notes
        )
        try await deliver("patient-home", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayPaymentRatesNumberRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayPaymentRatesNumberSink = ReplayPaymentRatesNumberLogOnly()
        switch kind {
        case "prescription-approval":
            sink = ReplayPaymentRatesNumberPrescriptionApproval(client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh))
        case "search-index-validation":
            sink = ReplayPaymentRatesNumberSearchIndexValidation(client: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh))
        case "patient-home":
            sink = ReplayPaymentRatesNumberPatientHome(client: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
