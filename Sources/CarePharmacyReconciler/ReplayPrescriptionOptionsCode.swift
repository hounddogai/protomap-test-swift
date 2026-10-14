import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayPrescriptionOptionsCode keeps of each ComparePrescriptionOptions response.
struct ReplayPrescriptionOptionsCodeRecord {
    var currencyCode: String
    var prescriptionID: String
    var message: String
    var notes: String
}

/// Where ReplayPrescriptionOptionsCode hands each record.
protocol ReplayPrescriptionOptionsCodeDestination {
    func apply(_ rec: ReplayPrescriptionOptionsCodeRecord) async throws
}

/// Sends records to acme.careplans.v1.CarePlanService.
struct ReplayPrescriptionOptionsCodeCarePlan: ReplayPrescriptionOptionsCodeDestination {
    let client: Acme_Careplans_V1_CarePlanService.Client<MeshTransport>

    func apply(_ rec: ReplayPrescriptionOptionsCodeRecord) async throws {
        let request = Acme_Careplans_V1_CreateCarePlanRequest.with {
            $0.carePlan.carePlanID = rec.prescriptionID
            $0.carePlan.number = rec.currencyCode
            $0.requestID = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.createCarePlan(request)
        }
    }
}

/// Sends records to acme.prescriptions.v1.MedicationWorkflowService.
struct ReplayPrescriptionOptionsCodeMedicationWorkflow: ReplayPrescriptionOptionsCodeDestination {
    let client: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>

    func apply(_ rec: ReplayPrescriptionOptionsCodeRecord) async throws {
        _ = try await client.listMedicationWorkflows(.with {
            $0.filter.region = rec.notes
            $0.filter.ownerID = rec.prescriptionID
            $0.filter.query = rec.message
        })
    }
}

/// Reads acme.prescriptions.v1.PrescriptionCalculationService/ComparePrescriptionOptions and hands what it keeps to the sink of its kind.
enum ReplayPrescriptionOptionsCode {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_PrescriptionCalculationService.Client(wrapping: mesh)
        let found = try await upstream.comparePrescriptionOptions(.with { $0.prescriptionID = "nightly-replay-prescription-options-code" })
        let entry = ReplayPrescriptionOptionsCodeRecord(
            currencyCode: found.breakdown.currencyCode,
            prescriptionID: found.prescription.prescriptionID,
            message: found.result.message,
            notes: Kit.Text.normalize(found.prescription.notes)
        )
        let sinks: [String: any ReplayPrescriptionOptionsCodeDestination] = [
            "care-plan": ReplayPrescriptionOptionsCodeCarePlan(client: Acme_Careplans_V1_CarePlanService.Client(wrapping: mesh)),
            "medication-workflow": ReplayPrescriptionOptionsCodeMedicationWorkflow(client: Acme_Prescriptions_V1_MedicationWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("care-plan", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ReplayPrescriptionOptionsCodeRecord, _ sinks: [String: any ReplayPrescriptionOptionsCodeDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
