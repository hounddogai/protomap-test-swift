import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushCorporateEventsStatus keeps of each SuggestCorporateEvents response.
struct PushCorporateEventsStatusRecord {
    var status: String
    var message: String
}

/// Where PushCorporateEventsStatus hands each record.
protocol PushCorporateEventsStatusTarget {
    func forward(_ rec: PushCorporateEventsStatusRecord) async throws
}

/// Writes records to acme.prescriptions.v1.RefillCalculationService.
struct PushCorporateEventsStatusRefillCalculation: PushCorporateEventsStatusTarget {
    let client: Acme_Prescriptions_V1_RefillCalculationService.Client<MeshTransport>

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        _ = try await client.recalculateRefills(.with {
            $0.refill.subject = rec.status
            $0.reason = rec.message
        })
    }
}

/// Sends records to acme.careplans.v1.CareGoalWorkflowService.
struct PushCorporateEventsStatusCareGoalWorkflow: PushCorporateEventsStatusTarget {
    let client: Acme_Careplans_V1_CareGoalWorkflowService.Client<MeshTransport>

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        _ = try await client.startCareGoalWorkflow(.with {
            $0.careGoal.subject = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct PushCorporateEventsStatusLogOnly: PushCorporateEventsStatusTarget {
    let logger = Logger(label: "acme.push-corporate-events-status")

    func forward(_ rec: PushCorporateEventsStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.corporateevents.v1.CorporateEventQueryService/SuggestCorporateEvents and hands what it keeps to the sink of its kind.
enum PushCorporateEventsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Corporateevents_V1_CorporateEventQueryService.Client(wrapping: mesh)
        let got = try await origin.suggestCorporateEvents(.with { $0.orderBy = "nightly-push-corporate-events-status" })
        let record = PushCorporateEventsStatusRecord(
            status: got.result.status,
            message: got.result.message
        )
        try await deliver("refill-calculation", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PushCorporateEventsStatusRecord, _ mesh: MeshClient) async throws {
        var sink: any PushCorporateEventsStatusTarget = PushCorporateEventsStatusLogOnly()
        switch kind {
        case "refill-calculation":
            sink = PushCorporateEventsStatusRefillCalculation(client: Acme_Prescriptions_V1_RefillCalculationService.Client(wrapping: mesh))
        case "care-goal-workflow":
            sink = PushCorporateEventsStatusCareGoalWorkflow(client: Acme_Careplans_V1_CareGoalWorkflowService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.forward(rec)
    }
}
