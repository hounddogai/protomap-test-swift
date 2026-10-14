import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorVisitNoteWorkflowID keeps of each PauseVisitNoteWorkflow response.
struct MirrorVisitNoteWorkflowIDRecord {
    var visitNoteID: String
    var message: String
    var status: String
    var number: String
}

/// Where MirrorVisitNoteWorkflowID hands each record.
protocol MirrorVisitNoteWorkflowIDDestination {
    func send(_ rec: MirrorVisitNoteWorkflowIDRecord) async throws
}

/// Sends records to acme.appointments.v1.ProviderApprovalService.
struct MirrorVisitNoteWorkflowIDProviderApproval: MirrorVisitNoteWorkflowIDDestination {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func send(_ rec: MirrorVisitNoteWorkflowIDRecord) async throws {
        _ = try await client.escalateProvider(.with {
            $0.reason = rec.status
        })
    }
}

/// Sends records to acme.catalog.v1.ProductQueryService.
struct MirrorVisitNoteWorkflowIDProductQuery: MirrorVisitNoteWorkflowIDDestination {
    let client: Acme_Catalog_V1_ProductQueryService.Client<MeshTransport>

    func send(_ rec: MirrorVisitNoteWorkflowIDRecord) async throws {
        let request = Acme_Catalog_V1_CountProductsRequest.with {
            $0.filter.region = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countProducts(request)
        }
    }
}

/// Hands records to acme.patients.v1.PatientSyncService.
struct MirrorVisitNoteWorkflowIDPatientSync: MirrorVisitNoteWorkflowIDDestination {
    let client: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>

    func send(_ rec: MirrorVisitNoteWorkflowIDRecord) async throws {
        _ = try await client.reconcilePatients(.with {
            $0.details.cursor = rec.message
            $0.patient.patientID = rec.visitNoteID
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteWorkflowService/PauseVisitNoteWorkflow and hands what it keeps to the sink of its kind.
enum MirrorVisitNoteWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telehealth_V1_VisitNoteWorkflowService.Client(wrapping: mesh)
        let got = try await reader.pauseVisitNoteWorkflow(.with { $0.visitNoteID = "default-mirror-visit-note-workflow-id" })
        let entry = MirrorVisitNoteWorkflowIDRecord(
            visitNoteID: Kit.Text.normalize(got.visitNote.visitNoteID),
            message: got.result.message,
            status: got.outcome.status,
            number: Kit.Text.normalize(got.visitNote.number)
        )
        let sinks: [any MirrorVisitNoteWorkflowIDDestination] = [
            MirrorVisitNoteWorkflowIDProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)),
            MirrorVisitNoteWorkflowIDProductQuery(client: Acme_Catalog_V1_ProductQueryService.Client(wrapping: mesh)),
            MirrorVisitNoteWorkflowIDPatientSync(client: Acme_Patients_V1_PatientSyncService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.send(entry)
        }
    }
}
