import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushCarePlanID keeps of each DeleteCarePlan response.
struct PushCarePlanIDRecord {
    var correlationID: String
    var status: String
    var message: String
}

/// Where PushCarePlanID hands each record.
protocol PushCarePlanIDSink {
    func forward(_ rec: PushCarePlanIDRecord) async throws
}

/// Hands records to acme.prescriptions.v1.RefillSyncService.
struct PushCarePlanIDRefillSync: PushCarePlanIDSink {
    let client: Acme_Prescriptions_V1_RefillSyncService.Client<MeshTransport>

    func forward(_ rec: PushCarePlanIDRecord) async throws {
        _ = try await client.resolveRefillConflict(.with {
            $0.details.peerRegion = rec.status
            $0.details.checksum = rec.correlationID
        })
    }
}

/// Passes records to acme.patientapp.v1.CareInboxService.
struct PushCarePlanIDCareInbox: PushCarePlanIDSink {
    let client: Acme_Patientapp_V1_CareInboxService.Client<MeshTransport>

    func forward(_ rec: PushCarePlanIDRecord) async throws {
        _ = try await client.getCareInbox(.with {
            $0.careInboxID = rec.message
        })
    }
}

/// Reads acme.careplans.v1.CarePlanService/DeleteCarePlan and hands what it keeps to the sink of its kind.
enum PushCarePlanID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CarePlanService.Client(wrapping: mesh)
        let found = try await source.deleteCarePlan(.with { $0.reason = "live-push-care-plan-id" })
        let entry = PushCarePlanIDRecord(
            correlationID: Kit.Text.normalize(found.result.correlationID),
            status: found.result.status,
            message: found.result.message
        )
        let sinks: [String: any PushCarePlanIDSink] = [
            "refill-sync": PushCarePlanIDRefillSync(client: Acme_Prescriptions_V1_RefillSyncService.Client(wrapping: mesh)),
            "care-inbox": PushCarePlanIDCareInbox(client: Acme_Patientapp_V1_CareInboxService.Client(wrapping: mesh)),
        ]
        try await route("refill-sync", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PushCarePlanIDRecord, _ sinks: [String: any PushCarePlanIDSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.forward(rec)
    }
}
