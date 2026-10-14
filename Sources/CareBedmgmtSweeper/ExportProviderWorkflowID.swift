import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ExportProviderWorkflowID keeps of each ResumeProviderWorkflow response.
struct ExportProviderWorkflowIDRecord {
    var correlationID: String
    var providerID: String
    var status: String
    var outcomeStatus: String
}

/// Where ExportProviderWorkflowID hands each record.
protocol ExportProviderWorkflowIDDestination {
    func send(_ rec: ExportProviderWorkflowIDRecord) async throws
}

/// Passes records to acme.audit.v1.AuditEventValidationService.
struct ExportProviderWorkflowIDAuditEventValidation: ExportProviderWorkflowIDDestination {
    let client: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>

    func send(_ rec: ExportProviderWorkflowIDRecord) async throws {
        _ = try await client.normalizeAuditEvent(.with {
            $0.details.locale = rec.correlationID
            $0.auditEvent.auditEventID = rec.status
            $0.auditEvent.source = rec.outcomeStatus
        })
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeService.
struct ExportProviderWorkflowIDPatientHome: ExportProviderWorkflowIDDestination {
    let client: Acme_Patientapp_V1_PatientHomeService.Client<MeshTransport>

    func send(_ rec: ExportProviderWorkflowIDRecord) async throws {
        _ = try await client.deletePatientHome(.with {
            $0.patientHomeID = rec.status
            $0.etag = rec.correlationID
        })
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionApprovalService.
struct ExportProviderWorkflowIDPrescriptionApproval: ExportProviderWorkflowIDDestination {
    let client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>

    func send(_ rec: ExportProviderWorkflowIDRecord) async throws {
        let request = Acme_Prescriptions_V1_ApprovePrescriptionRequest.with {
            $0.prescription.notes = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.approvePrescription(request)
        }
    }
}

/// Sends records to acme.broadcasts.v1.BroadcastQueryService.
struct ExportProviderWorkflowIDBroadcastQuery: ExportProviderWorkflowIDDestination {
    let client: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>

    func send(_ rec: ExportProviderWorkflowIDRecord) async throws {
        _ = try await client.countBroadcasts(.with {
            $0.page.pageToken = rec.outcomeStatus
            $0.filter.ownerID = rec.correlationID
        })
    }
}

/// Reads acme.appointments.v1.ProviderWorkflowService/ResumeProviderWorkflow and hands what it keeps to the sink of its kind.
enum ExportProviderWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh)
        let response = try await origin.resumeProviderWorkflow(.with { $0.reason = "live-export-provider-workflow-id" })
        let rec = ExportProviderWorkflowIDRecord(
            correlationID: response.result.correlationID,
            providerID: Kit.Text.normalize(response.provider.providerID),
            status: response.result.status,
            outcomeStatus: Kit.Text.normalize(response.outcome.status)
        )
        let sinks: [any ExportProviderWorkflowIDDestination] = [
            ExportProviderWorkflowIDAuditEventValidation(client: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)),
            ExportProviderWorkflowIDPatientHome(client: Acme_Patientapp_V1_PatientHomeService.Client(wrapping: mesh)),
            ExportProviderWorkflowIDPrescriptionApproval(client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh)),
            ExportProviderWorkflowIDBroadcastQuery(client: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[3].send(rec)
    }
}
