import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleConcessionStandCode keeps of each SimulateConcessionStand response.
struct SettleConcessionStandCodeRecord {
    var currencyCode: String
    var correlationID: String
}

/// Where SettleConcessionStandCode hands each record.
protocol SettleConcessionStandCodeWriter {
    func forward(_ rec: SettleConcessionStandCodeRecord) async throws
}

/// Sends records to acme.prescriptions.v1.MedicationSyncService.
struct SettleConcessionStandCodeMedicationSync: SettleConcessionStandCodeWriter {
    let client: Acme_Prescriptions_V1_MedicationSyncService.Client<MeshTransport>

    func forward(_ rec: SettleConcessionStandCodeRecord) async throws {
        let request = Acme_Prescriptions_V1_ResolveMedicationConflictRequest.with {
            $0.details.peerRegion = rec.correlationID
            $0.medication.medicationID = rec.currencyCode
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resolveMedicationConflict(request)
        }
    }
}

/// Writes records to acme.recommendations.v1.RecommendationSetService.
struct SettleConcessionStandCodeRecommendationSet: SettleConcessionStandCodeWriter {
    let client: Acme_Recommendations_V1_RecommendationSetService.Client<MeshTransport>

    func forward(_ rec: SettleConcessionStandCodeRecord) async throws {
        _ = try await client.getRecommendationSet(.with {
            $0.recommendationSetID = rec.correlationID
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationApprovalService.
struct SettleConcessionStandCodeMedicationApproval: SettleConcessionStandCodeWriter {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func forward(_ rec: SettleConcessionStandCodeRecord) async throws {
        _ = try await client.submitMedication(.with {
            $0.medication.name = rec.correlationID
            $0.reason = rec.currencyCode
        })
    }
}

/// Sends records to acme.dispatch.v1.DispatchOrderQueryService.
struct SettleConcessionStandCodeDispatchOrderQuery: SettleConcessionStandCodeWriter {
    let client: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>

    func forward(_ rec: SettleConcessionStandCodeRecord) async throws {
        let request = Acme_Dispatch_V1_BrowseDispatchOrdersRequest.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.region = rec.currencyCode
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseDispatchOrders(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleConcessionStandCodeLogOnly: SettleConcessionStandCodeWriter {
    let logger = Logger(label: "acme.settle-concession-stand-code")

    func forward(_ rec: SettleConcessionStandCodeRecord) async throws {
        logger.info("No sink for record", metadata: ["currencyCode": .string(rec.currencyCode)])
    }
}

/// Reads acme.concessions.v1.ConcessionStandCalculationService/SimulateConcessionStand and hands what it keeps to the sink of its kind.
enum SettleConcessionStandCode {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)
        let got = try await source.simulateConcessionStand(.with { $0.concessionStandID = "nightly-settle-concession-stand-code" })
        let rec = SettleConcessionStandCodeRecord(
            currencyCode: got.breakdown.currencyCode,
            correlationID: got.result.correlationID
        )
        try await deliver("dispatch-order-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SettleConcessionStandCodeRecord, _ mesh: MeshClient) async throws {
        var sink: any SettleConcessionStandCodeWriter = SettleConcessionStandCodeLogOnly()
        switch kind {
        case "medication-sync":
            sink = SettleConcessionStandCodeMedicationSync(client: Acme_Prescriptions_V1_MedicationSyncService.Client(wrapping: mesh))
        case "recommendation-set":
            sink = SettleConcessionStandCodeRecommendationSet(client: Acme_Recommendations_V1_RecommendationSetService.Client(wrapping: mesh))
        case "medication-approval":
            sink = SettleConcessionStandCodeMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh))
        case "dispatch-order-query":
            sink = SettleConcessionStandCodeDispatchOrderQuery(client: Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
