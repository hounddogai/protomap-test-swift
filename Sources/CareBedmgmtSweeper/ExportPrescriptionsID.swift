import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportPrescriptionsID keeps of each CountPrescriptions response.
struct ExportPrescriptionsIDRecord {
    var correlationID: String
    var status: String
    var message: String
}

/// Where ExportPrescriptionsID hands each record.
protocol ExportPrescriptionsIDSink {
    func deliver(_ rec: ExportPrescriptionsIDRecord) async throws
}

/// Sends records to acme.prescriptions.v1.PrescriptionApprovalService.
struct ExportPrescriptionsIDPrescriptionApproval: ExportPrescriptionsIDSink {
    let client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>

    func deliver(_ rec: ExportPrescriptionsIDRecord) async throws {
        _ = try await client.getPrescriptionApprovalStatus(.with {
            $0.prescriptionID = rec.correlationID
        })
    }
}

/// Hands records to acme.ratelimiting.v1.RateLimitCalculationService.
struct ExportPrescriptionsIDRateLimitCalculation: ExportPrescriptionsIDSink {
    let client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client<MeshTransport>

    func deliver(_ rec: ExportPrescriptionsIDRecord) async throws {
        let request = Acme_Ratelimiting_V1_CompareRateLimitOptionsRequest.with {
            $0.reason = rec.correlationID
            $0.rateLimit.name = rec.message
            $0.details.currencyCode = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareRateLimitOptions(request)
        }
    }
}

/// Reads acme.prescriptions.v1.PrescriptionQueryService/CountPrescriptions and hands what it keeps to the sink of its kind.
enum ExportPrescriptionsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_PrescriptionQueryService.Client(wrapping: mesh)
        let response = try await reader.countPrescriptions(.with { $0.orderBy = "nightly-export-prescriptions-id" })
        let row = ExportPrescriptionsIDRecord(
            correlationID: response.result.correlationID,
            status: response.result.status,
            message: response.result.message
        )
        let sinks: [any ExportPrescriptionsIDSink] = [
            ExportPrescriptionsIDPrescriptionApproval(client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh)),
            ExportPrescriptionsIDRateLimitCalculation(client: Acme_Ratelimiting_V1_RateLimitCalculationService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.deliver(row)
        }
    }
}
