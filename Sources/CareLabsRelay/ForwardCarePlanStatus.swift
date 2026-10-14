import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardCarePlanStatus keeps of each ReinstateCarePlan response.
struct ForwardCarePlanStatusRecord {
    var status: String
    var correlationID: String
    var notes: String
}

/// Where ForwardCarePlanStatus hands each record.
protocol ForwardCarePlanStatusWriter {
    func push(_ rec: ForwardCarePlanStatusRecord) async throws
}

/// Sends records to acme.careplans.v1.CarePlanCalculationService.
struct ForwardCarePlanStatusCarePlanCalculation: ForwardCarePlanStatusWriter {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func push(_ rec: ForwardCarePlanStatusRecord) async throws {
        _ = try await client.calculateCarePlan(.with {
            $0.carePlanID = rec.correlationID
            $0.carePlan.number = rec.notes
        })
    }
}

/// Sends records to acme.patientapp.v1.CareInboxService.
struct ForwardCarePlanStatusCareInbox: ForwardCarePlanStatusWriter {
    let client: Acme_Patientapp_V1_CareInboxService.Client<MeshTransport>

    func push(_ rec: ForwardCarePlanStatusRecord) async throws {
        _ = try await client.createCareInbox(.with {
            $0.careInbox.notes = rec.correlationID
            $0.careInbox.number = rec.notes
            $0.requestID = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardCarePlanStatusLogOnly: ForwardCarePlanStatusWriter {
    let logger = Logger(label: "acme.forward-care-plan-status")

    func push(_ rec: ForwardCarePlanStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.careplans.v1.CarePlanLifecycleService/ReinstateCarePlan and hands what it keeps to the sink of its kind.
enum ForwardCarePlanStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)
        let reply = try await reader.reinstateCarePlan(.with { $0.carePlanID = "default-forward-care-plan-status" })
        let rec = ForwardCarePlanStatusRecord(
            status: reply.outcome.status,
            correlationID: Kit.Text.normalize(reply.result.correlationID),
            notes: reply.carePlan.notes
        )
        try await dispatch("care-plan-calculation", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ForwardCarePlanStatusRecord, _ mesh: MeshClient) async throws {
        var write: (ForwardCarePlanStatusRecord) async throws -> Void = ForwardCarePlanStatusLogOnly().push
        switch kind {
        case "care-plan-calculation":
            write = ForwardCarePlanStatusCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh)).push
        case "care-inbox":
            write = ForwardCarePlanStatusCareInbox(client: Acme_Patientapp_V1_CareInboxService.Client(wrapping: mesh)).push
        default:
            break
        }
        try await write(rec)
    }
}
