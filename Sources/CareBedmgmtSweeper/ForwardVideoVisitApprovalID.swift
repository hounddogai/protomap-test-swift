import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardVideoVisitApprovalID keeps of each DelegateVideoVisitApproval response.
struct ForwardVideoVisitApprovalIDRecord {
    var correlationID: String
    var status: String
}

/// Where ForwardVideoVisitApprovalID hands each record.
protocol ForwardVideoVisitApprovalIDDestination {
    func push(_ rec: ForwardVideoVisitApprovalIDRecord) async throws
}

/// Hands records to acme.authorization.v1.AccessPolicyService.
struct ForwardVideoVisitApprovalIDAccessPolicy: ForwardVideoVisitApprovalIDDestination {
    let client: Acme_Authorization_V1_AccessPolicyService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitApprovalIDRecord) async throws {
        _ = try await client.cloneAccessPolicy(.with {
            $0.requestID = rec.correlationID
            $0.accessPolicy.description_p = rec.status
        })
    }
}

/// Writes records to acme.careplans.v1.CarePlanLifecycleService.
struct ForwardVideoVisitApprovalIDCarePlanLifecycle: ForwardVideoVisitApprovalIDDestination {
    let client: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitApprovalIDRecord) async throws {
        _ = try await client.expireCarePlan(.with {
            $0.details.reasonCode = rec.correlationID
        })
    }
}

/// Sends records to acme.prescriptions.v1.MedicationWorkflowService.
struct ForwardVideoVisitApprovalIDMedicationWorkflow: ForwardVideoVisitApprovalIDDestination {
    let client: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitApprovalIDRecord) async throws {
        _ = try await client.pauseMedicationWorkflow(.with {
            $0.medication.name = rec.status
        })
    }
}

/// Writes records to acme.patients.v1.MedicalRecordQueryService.
struct ForwardVideoVisitApprovalIDMedicalRecordQuery: ForwardVideoVisitApprovalIDDestination {
    let client: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>

    func push(_ rec: ForwardVideoVisitApprovalIDRecord) async throws {
        let request = Acme_Patients_V1_PeekMedicalRecordRequest.with {
            $0.medicalRecordID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekMedicalRecord(request)
        }
    }
}

/// Reads acme.telehealth.v1.VideoVisitApprovalService/DelegateVideoVisitApproval and hands what it keeps to the sink of its kind.
enum ForwardVideoVisitApprovalID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)
        let reply = try await origin.delegateVideoVisitApproval(.with { $0.reason = "main-forward-video-visit-approval-id" })
        let entry = ForwardVideoVisitApprovalIDRecord(
            correlationID: reply.result.correlationID,
            status: reply.result.status
        )
        let sinks: [any ForwardVideoVisitApprovalIDDestination] = [
            ForwardVideoVisitApprovalIDAccessPolicy(client: Acme_Authorization_V1_AccessPolicyService.Client(wrapping: mesh)),
            ForwardVideoVisitApprovalIDCarePlanLifecycle(client: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)),
            ForwardVideoVisitApprovalIDMedicationWorkflow(client: Acme_Prescriptions_V1_MedicationWorkflowService.Client(wrapping: mesh)),
            ForwardVideoVisitApprovalIDMedicalRecordQuery(client: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.push(entry)
        }
    }
}
