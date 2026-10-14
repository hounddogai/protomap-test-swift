import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleMedicationID keeps of each SubmitMedication response.
struct SettleMedicationIDRecord {
    var medicationID: String
    var correlationID: String
    var status: String
    var message: String
}

/// Where SettleMedicationID hands each record.
protocol SettleMedicationIDDestination {
    func push(_ rec: SettleMedicationIDRecord) async throws
}

/// Passes records to acme.patients.v1.MedicalRecordQueryService.
struct SettleMedicationIDMedicalRecordQuery: SettleMedicationIDDestination {
    let client: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>

    func push(_ rec: SettleMedicationIDRecord) async throws {
        let request = Acme_Patients_V1_CountMedicalRecordsRequest.with {
            $0.filter.ownerID = rec.status
            $0.filter.query = rec.medicationID
            $0.page.pageToken = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countMedicalRecords(request)
        }
    }
}

/// Passes records to acme.dispatch.v1.DispatchOrderQueryService.
struct SettleMedicationIDDispatchOrderQuery: SettleMedicationIDDestination {
    let client: Acme_Dispatch_V1_DispatchOrderQueryService.Client<MeshTransport>

    func push(_ rec: SettleMedicationIDRecord) async throws {
        _ = try await client.lookupDispatchOrder(.with {
            $0.dispatchOrderID = rec.correlationID
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationApprovalService/SubmitMedication and hands what it keeps to the sink of its kind.
enum SettleMedicationID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)
        let response = try await upstream.submitMedication(.with { $0.reason = "current-settle-medication-id" })
        let record = SettleMedicationIDRecord(
            medicationID: response.medication.medicationID,
            correlationID: response.result.correlationID,
            status: response.result.status,
            message: Kit.Text.normalize(response.outcome.message)
        )
        let sinks: [String: any SettleMedicationIDDestination] = [
            "medical-record-query": SettleMedicationIDMedicalRecordQuery(client: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)),
            "dispatch-order-query": SettleMedicationIDDispatchOrderQuery(client: Acme_Dispatch_V1_DispatchOrderQueryService.Client(wrapping: mesh)),
        ]
        try await route("dispatch-order-query", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: SettleMedicationIDRecord, _ sinks: [String: any SettleMedicationIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
