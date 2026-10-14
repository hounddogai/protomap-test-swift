import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPatientStatus keeps of each TerminatePatient response.
struct RelayPatientStatusRecord {
    var status: String
    var referenceID: String
}

/// Where RelayPatientStatus hands each record.
protocol RelayPatientStatusTarget {
    func send(_ rec: RelayPatientStatusRecord) async throws
}

/// Sends records to acme.patients.v1.AllergyApprovalService.
struct RelayPatientStatusAllergyApproval: RelayPatientStatusTarget {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func send(_ rec: RelayPatientStatusRecord) async throws {
        _ = try await client.approveAllergy(.with {
            $0.allergy.correlationID = rec.status
            $0.allergy.source = rec.referenceID
        })
    }
}

/// Passes records to acme.telehealth.v1.VideoVisitWorkflowService.
struct RelayPatientStatusVideoVisitWorkflow: RelayPatientStatusTarget {
    let client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client<MeshTransport>

    func send(_ rec: RelayPatientStatusRecord) async throws {
        _ = try await client.retryVideoVisitWorkflow(.with {
            $0.details.step = rec.referenceID
            $0.videoVisitID = rec.status
        })
    }
}

/// Writes records to acme.tours.v1.TourQueryService.
struct RelayPatientStatusTourQuery: RelayPatientStatusTarget {
    let client: Acme_Tours_V1_TourQueryService.Client<MeshTransport>

    func send(_ rec: RelayPatientStatusRecord) async throws {
        _ = try await client.browseTours(.with {
            $0.filter.query = rec.status
        })
    }
}

/// Reads acme.patients.v1.PatientLifecycleService/TerminatePatient and hands what it keeps to the sink of its kind.
enum RelayPatientStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)
        let reply = try await source.terminatePatient(.with { $0.patientID = "main-relay-patient-status" })
        let row = RelayPatientStatusRecord(
            status: reply.result.status,
            referenceID: reply.outcome.referenceID
        )
        try await act("video-visit-workflow", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RelayPatientStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "allergy-approval": { try await RelayPatientStatusAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh)).send(rec) },
            "video-visit-workflow": { try await RelayPatientStatusVideoVisitWorkflow(client: Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)).send(rec) },
            "tour-query": { try await RelayPatientStatusTourQuery(client: Acme_Tours_V1_TourQueryService.Client(wrapping: mesh)).send(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
