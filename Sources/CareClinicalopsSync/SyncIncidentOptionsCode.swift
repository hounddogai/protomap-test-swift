import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncIncidentOptionsCode keeps of each CompareIncidentOptions response.
struct SyncIncidentOptionsCodeRecord {
    var currencyCode: String
    var subject: String
    var status: String
    var message: String
}

/// Where SyncIncidentOptionsCode hands each record.
protocol SyncIncidentOptionsCodeSink {
    func forward(_ rec: SyncIncidentOptionsCodeRecord) async throws
}

/// Writes records to acme.prescriptions.v1.RefillValidationService.
struct SyncIncidentOptionsCodeRefillValidation: SyncIncidentOptionsCodeSink {
    let client: Acme_Prescriptions_V1_RefillValidationService.Client<MeshTransport>

    func forward(_ rec: SyncIncidentOptionsCodeRecord) async throws {
        let request = Acme_Prescriptions_V1_ScoreRefillRequest.with {
            $0.reason = rec.currencyCode
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreRefill(request)
        }
    }
}

/// Passes records to acme.anomalies.v1.AnomalyQueryService.
struct SyncIncidentOptionsCodeAnomalyQuery: SyncIncidentOptionsCodeSink {
    let client: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>

    func forward(_ rec: SyncIncidentOptionsCodeRecord) async throws {
        _ = try await client.findAnomalies(.with {
            $0.orderBy = rec.status
            $0.filter.region = rec.message
            $0.filter.ownerID = rec.currencyCode
        })
    }
}

/// Hands records to acme.patientapp.v1.PatientHomeWorkflowService.
struct SyncIncidentOptionsCodePatientHomeWorkflow: SyncIncidentOptionsCodeSink {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func forward(_ rec: SyncIncidentOptionsCodeRecord) async throws {
        let request = Acme_Patientapp_V1_AdvancePatientHomeWorkflowRequest.with {
            $0.details.initiatedBy = rec.currencyCode
            $0.reason = rec.status
            $0.patientHomeID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.advancePatientHomeWorkflow(request)
        }
    }
}

/// Reads acme.itsm.v1.IncidentCalculationService/CompareIncidentOptions and hands what it keeps to the sink of its kind.
enum SyncIncidentOptionsCode {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh)
        let reply = try await origin.compareIncidentOptions(.with { $0.reason = "live-sync-incident-options-code" })
        let entry = SyncIncidentOptionsCodeRecord(
            currencyCode: reply.breakdown.currencyCode,
            subject: Kit.Text.normalize(reply.incident.subject),
            status: reply.result.status,
            message: Kit.Text.normalize(reply.result.message)
        )
        let sinks: [String: any SyncIncidentOptionsCodeSink] = [
            "refill-validation": SyncIncidentOptionsCodeRefillValidation(client: Acme_Prescriptions_V1_RefillValidationService.Client(wrapping: mesh)),
            "anomaly-query": SyncIncidentOptionsCodeAnomalyQuery(client: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: mesh)),
            "patient-home-workflow": SyncIncidentOptionsCodePatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["SYNC_INCIDENT_OPTIONS_CODE_TARGET"] ?? ""] else {
            return
        }
        try await sink.forward(entry)
    }
}
