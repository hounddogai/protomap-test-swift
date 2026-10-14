import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncPatientHomeWorkflowMessage keeps of each ResumePatientHomeWorkflow response.
struct SyncPatientHomeWorkflowMessageRecord {
    var message: String
    var subject: String
    var correlationID: String
}

/// Where SyncPatientHomeWorkflowMessage hands each record.
protocol SyncPatientHomeWorkflowMessageDestination {
    func deliver(_ rec: SyncPatientHomeWorkflowMessageRecord) async throws
}

/// Hands records to acme.boxoffice.v1.BoxOfficeSaleQueryService.
struct SyncPatientHomeWorkflowMessageBoxOfficeSaleQuery: SyncPatientHomeWorkflowMessageDestination {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>

    func deliver(_ rec: SyncPatientHomeWorkflowMessageRecord) async throws {
        let request = Acme_Boxoffice_V1_FindBoxOfficeSalesRequest.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.subject
            $0.orderBy = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.findBoxOfficeSales(request)
        }
    }
}

/// Passes records to acme.patients.v1.MedicalRecordApprovalService.
struct SyncPatientHomeWorkflowMessageMedicalRecordApproval: SyncPatientHomeWorkflowMessageDestination {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func deliver(_ rec: SyncPatientHomeWorkflowMessageRecord) async throws {
        let request = Acme_Patients_V1_ListPendingMedicalRecordsRequest.with {
            $0.filter.ownerID = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listPendingMedicalRecords(request)
        }
    }
}

/// Writes records to acme.careplans.v1.CareGoalLifecycleService.
struct SyncPatientHomeWorkflowMessageCareGoalLifecycle: SyncPatientHomeWorkflowMessageDestination {
    let client: Acme_Careplans_V1_CareGoalLifecycleService.Client<MeshTransport>

    func deliver(_ rec: SyncPatientHomeWorkflowMessageRecord) async throws {
        _ = try await client.activateCareGoal(.with {
            $0.reason = rec.message
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeWorkflowService/ResumePatientHomeWorkflow and hands what it keeps to the sink of its kind.
enum SyncPatientHomeWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)
        let reply = try await source.resumePatientHomeWorkflow(.with { $0.reason = "current-sync-patient-home-workflow-message" })
        let entry = SyncPatientHomeWorkflowMessageRecord(
            message: reply.outcome.message,
            subject: Kit.Text.normalize(reply.patientHome.subject),
            correlationID: reply.result.correlationID
        )
        let sinks: [String: any SyncPatientHomeWorkflowMessageDestination] = [
            "box-office-sale-query": SyncPatientHomeWorkflowMessageBoxOfficeSaleQuery(client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)),
            "medical-record-approval": SyncPatientHomeWorkflowMessageMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)),
            "care-goal-lifecycle": SyncPatientHomeWorkflowMessageCareGoalLifecycle(client: Acme_Careplans_V1_CareGoalLifecycleService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "medical-record-approval" {
                continue
            }
            try await sink.deliver(entry)
        }
    }
}
