import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncSearchIndexID keeps of each UpdateSearchIndex response.
struct SyncSearchIndexIDRecord {
    var searchIndexID: String
    var correlationID: String
}

/// Where SyncSearchIndexID hands each record.
protocol SyncSearchIndexIDWriter {
    func send(_ rec: SyncSearchIndexIDRecord) async throws
}

/// Writes records to acme.appointments.v1.ClinicSlotValidationService.
struct SyncSearchIndexIDClinicSlotValidation: SyncSearchIndexIDWriter {
    let client: Acme_Appointments_V1_ClinicSlotValidationService.Client<MeshTransport>

    func send(_ rec: SyncSearchIndexIDRecord) async throws {
        let request = Acme_Appointments_V1_NormalizeClinicSlotRequest.with {
            $0.clinicSlotID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.normalizeClinicSlot(request)
        }
    }
}

/// Writes records to acme.appointments.v1.ClinicSlotWorkflowService.
struct SyncSearchIndexIDClinicSlotWorkflow: SyncSearchIndexIDWriter {
    let client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>

    func send(_ rec: SyncSearchIndexIDRecord) async throws {
        let request = Acme_Appointments_V1_StartClinicSlotWorkflowRequest.with {
            $0.clinicSlot.title = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.startClinicSlotWorkflow(request)
        }
    }
}

/// Reads acme.search.v1.SearchIndexService/UpdateSearchIndex and hands what it keeps to the sink of its kind.
enum SyncSearchIndexID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Search_V1_SearchIndexService.Client(wrapping: mesh)
        let got = try await reader.updateSearchIndex(.init())
        let entry = SyncSearchIndexIDRecord(
            searchIndexID: got.searchIndex.searchIndexID,
            correlationID: Kit.Text.normalize(got.result.correlationID)
        )
        let sinks: [String: any SyncSearchIndexIDWriter] = [
            "clinic-slot-validation": SyncSearchIndexIDClinicSlotValidation(client: Acme_Appointments_V1_ClinicSlotValidationService.Client(wrapping: mesh)),
            "clinic-slot-workflow": SyncSearchIndexIDClinicSlotWorkflow(client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "clinic-slot-validation" {
                continue
            }
            try await sink.send(entry)
        }
    }
}
