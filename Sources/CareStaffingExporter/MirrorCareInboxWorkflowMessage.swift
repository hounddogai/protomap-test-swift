import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorCareInboxWorkflowMessage keeps of each RetryCareInboxWorkflow response.
struct MirrorCareInboxWorkflowMessageRecord {
    var message: String
    var outcomeMessage: String
}

/// Where MirrorCareInboxWorkflowMessage hands each record.
protocol MirrorCareInboxWorkflowMessageWriter {
    func apply(_ rec: MirrorCareInboxWorkflowMessageRecord) async throws
}

/// Passes records to acme.anomalies.v1.AnomalyQueryService.
struct MirrorCareInboxWorkflowMessageAnomalyQuery: MirrorCareInboxWorkflowMessageWriter {
    let client: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>

    func apply(_ rec: MirrorCareInboxWorkflowMessageRecord) async throws {
        let request = Acme_Anomalies_V1_FindAnomaliesRequest.with {
            $0.filter.ownerID = rec.message
            $0.filter.region = rec.outcomeMessage
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findAnomalies(request)
        }
    }
}

/// Passes records to acme.patients.v1.AllergySyncService.
struct MirrorCareInboxWorkflowMessageAllergySync: MirrorCareInboxWorkflowMessageWriter {
    let client: Acme_Patients_V1_AllergySyncService.Client<MeshTransport>

    func apply(_ rec: MirrorCareInboxWorkflowMessageRecord) async throws {
        let request = Acme_Patients_V1_SyncAllergiesRequest.with {
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.syncAllergies(request)
        }
    }
}

/// Reads acme.patientapp.v1.CareInboxWorkflowService/RetryCareInboxWorkflow and hands what it keeps to the sink of its kind.
enum MirrorCareInboxWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)
        let found = try await upstream.retryCareInboxWorkflow(.with { $0.reason = "primary-mirror-care-inbox-workflow-message" })
        let entry = MirrorCareInboxWorkflowMessageRecord(
            message: Kit.Text.normalize(found.result.message),
            outcomeMessage: found.outcome.message
        )
        let sinks: [String: any MirrorCareInboxWorkflowMessageWriter] = [
            "anomaly-query": MirrorCareInboxWorkflowMessageAnomalyQuery(client: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: mesh)),
            "allergy-sync": MirrorCareInboxWorkflowMessageAllergySync(client: Acme_Patients_V1_AllergySyncService.Client(wrapping: mesh)),
        ]
        try await route("anomaly-query", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: MirrorCareInboxWorkflowMessageRecord, _ sinks: [String: any MirrorCareInboxWorkflowMessageWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
