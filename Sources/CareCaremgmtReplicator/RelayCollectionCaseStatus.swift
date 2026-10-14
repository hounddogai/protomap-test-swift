import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayCollectionCaseStatus keeps of each DeleteCollectionCase response.
struct RelayCollectionCaseStatusRecord {
    var status: String
    var correlationID: String
    var message: String
}

/// Where RelayCollectionCaseStatus hands each record.
protocol RelayCollectionCaseStatusSink {
    func write(_ rec: RelayCollectionCaseStatusRecord) async throws
}

/// Hands records to acme.patients.v1.PatientReportingService.
struct RelayCollectionCaseStatusPatientReporting: RelayCollectionCaseStatusSink {
    let client: Acme_Patients_V1_PatientReportingService.Client<MeshTransport>

    func write(_ rec: RelayCollectionCaseStatusRecord) async throws {
        _ = try await client.countPatientTotals(.with {
            $0.orderBy = rec.status
            $0.filter.region = rec.message
        })
    }
}

/// Hands records to acme.payments.v1.PaymentCalculationService.
struct RelayCollectionCaseStatusPaymentCalculation: RelayCollectionCaseStatusSink {
    let client: Acme_Payments_V1_PaymentCalculationService.Client<MeshTransport>

    func write(_ rec: RelayCollectionCaseStatusRecord) async throws {
        let request = Acme_Payments_V1_RecalculatePaymentsRequest.with {
            $0.paymentID = rec.status
            $0.payment.paymentID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.recalculatePayments(request)
        }
    }
}

/// Hands records to acme.audiences.v1.AudienceService.
struct RelayCollectionCaseStatusAudience: RelayCollectionCaseStatusSink {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func write(_ rec: RelayCollectionCaseStatusRecord) async throws {
        let request = Acme_Audiences_V1_SearchAudiencesRequest.with {
            $0.orderBy = rec.correlationID
            $0.filter.region = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchAudiences(request)
        }
    }
}

/// Reads acme.collections.v1.CollectionCaseService/DeleteCollectionCase and hands what it keeps to the sink of its kind.
enum RelayCollectionCaseStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Collections_V1_CollectionCaseService.Client(wrapping: mesh)
        let got = try await upstream.deleteCollectionCase(.with { $0.reason = "main-relay-collection-case-status" })
        let rec = RelayCollectionCaseStatusRecord(
            status: got.result.status,
            correlationID: got.result.correlationID,
            message: got.result.message
        )
        let sinks: [String: any RelayCollectionCaseStatusSink] = [
            "patient-reporting": RelayCollectionCaseStatusPatientReporting(client: Acme_Patients_V1_PatientReportingService.Client(wrapping: mesh)),
            "payment-calculation": RelayCollectionCaseStatusPaymentCalculation(client: Acme_Payments_V1_PaymentCalculationService.Client(wrapping: mesh)),
            "audience": RelayCollectionCaseStatusAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "audience" {
                continue
            }
            try await sink.write(rec)
        }
    }
}
