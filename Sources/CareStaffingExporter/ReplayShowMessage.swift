import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayShowMessage keeps of each CreateShow response.
struct ReplayShowMessageRecord {
    var message: String
    var showID: String
    var status: String
}

/// Where ReplayShowMessage hands each record.
protocol ReplayShowMessageTarget {
    func forward(_ rec: ReplayShowMessageRecord) async throws
}

/// Passes records to acme.appointments.v1.ProviderWorkflowService.
struct ReplayShowMessageProviderWorkflow: ReplayShowMessageTarget {
    let client: Acme_Appointments_V1_ProviderWorkflowService.Client<MeshTransport>

    func forward(_ rec: ReplayShowMessageRecord) async throws {
        let request = Acme_Appointments_V1_ListProviderWorkflowsRequest.with {
            $0.orderBy = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listProviderWorkflows(request)
        }
    }
}

/// Sends records to acme.prescriptions.v1.MedicationValidationService.
struct ReplayShowMessageMedicationValidation: ReplayShowMessageTarget {
    let client: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>

    func forward(_ rec: ReplayShowMessageRecord) async throws {
        _ = try await client.getMedicationRules(.with {
            $0.medicationID = rec.status
        })
    }
}

/// Reads acme.shows.v1.ShowService/CreateShow and hands what it keeps to the sink of its kind.
enum ReplayShowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Shows_V1_ShowService.Client(wrapping: mesh)
        let found = try await upstream.createShow(.with { $0.requestID = "nightly-replay-show-message" })
        let rec = ReplayShowMessageRecord(
            message: found.result.message,
            showID: found.show.showID,
            status: Kit.Text.normalize(found.result.status)
        )
        let sinks: [String: any ReplayShowMessageTarget] = [
            "provider-workflow": ReplayShowMessageProviderWorkflow(client: Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh)),
            "medication-validation": ReplayShowMessageMedicationValidation(client: Acme_Prescriptions_V1_MedicationValidationService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["REPLAY_SHOW_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.forward(rec)
    }
}
