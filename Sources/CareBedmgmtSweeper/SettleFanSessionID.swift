import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleFanSessionID keeps of each DeleteFanSession response.
struct SettleFanSessionIDRecord {
    var correlationID: String
    var message: String
    var status: String
}

/// Where SettleFanSessionID hands each record.
protocol SettleFanSessionIDSink {
    func write(_ rec: SettleFanSessionIDRecord) async throws
}

/// Passes records to acme.patients.v1.MedicalRecordWorkflowService.
struct SettleFanSessionIDMedicalRecordWorkflow: SettleFanSessionIDSink {
    let client: Acme_Patients_V1_MedicalRecordWorkflowService.Client<MeshTransport>

    func write(_ rec: SettleFanSessionIDRecord) async throws {
        _ = try await client.pauseMedicalRecordWorkflow(.with {
            $0.details.initiatedBy = rec.message
            $0.medicalRecord.medicalRecordID = rec.correlationID
            $0.reason = rec.status
        })
    }
}

/// Writes records to acme.deliveries.v1.DeliveryService.
struct SettleFanSessionIDDelivery: SettleFanSessionIDSink {
    let client: Acme_Deliveries_V1_DeliveryService.Client<MeshTransport>

    func write(_ rec: SettleFanSessionIDRecord) async throws {
        let request = Acme_Deliveries_V1_ListDeliveriesRequest.with {
            $0.filter.ownerID = rec.correlationID
            $0.filter.query = rec.status
            $0.filter.region = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.listDeliveries(request)
        }
    }
}

/// Hands records to acme.patients.v1.AllergyWorkflowService.
struct SettleFanSessionIDAllergyWorkflow: SettleFanSessionIDSink {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func write(_ rec: SettleFanSessionIDRecord) async throws {
        let request = Acme_Patients_V1_StartAllergyWorkflowRequest.with {
            $0.details.step = rec.status
            $0.reason = rec.message
            $0.allergy.source = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.startAllergyWorkflow(request)
        }
    }
}

/// Reads acme.fanportal.v1.FanSessionService/DeleteFanSession and hands what it keeps to the sink of its kind.
enum SettleFanSessionID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Fanportal_V1_FanSessionService.Client(wrapping: mesh)
        let reply = try await source.deleteFanSession(.with { $0.reason = "nightly-settle-fan-session-id" })
        let record = SettleFanSessionIDRecord(
            correlationID: reply.result.correlationID,
            message: reply.result.message,
            status: Kit.Text.normalize(reply.result.status)
        )
        try await act("allergy-workflow", record, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: SettleFanSessionIDRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "medical-record-workflow": { try await SettleFanSessionIDMedicalRecordWorkflow(client: Acme_Patients_V1_MedicalRecordWorkflowService.Client(wrapping: mesh)).write(rec) },
            "delivery": { try await SettleFanSessionIDDelivery(client: Acme_Deliveries_V1_DeliveryService.Client(wrapping: mesh)).write(rec) },
            "allergy-workflow": { try await SettleFanSessionIDAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)).write(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
