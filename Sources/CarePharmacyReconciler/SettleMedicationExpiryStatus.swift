import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleMedicationExpiryStatus keeps of each ScheduleMedicationExpiry response.
struct SettleMedicationExpiryStatusRecord {
    var status: String
    var resultStatus: String
    var message: String
}

/// Where SettleMedicationExpiryStatus hands each record.
protocol SettleMedicationExpiryStatusDestination {
    func push(_ rec: SettleMedicationExpiryStatusRecord) async throws
}

/// Passes records to acme.itsm.v1.IncidentCalculationService.
struct SettleMedicationExpiryStatusIncidentCalculation: SettleMedicationExpiryStatusDestination {
    let client: Acme_Itsm_V1_IncidentCalculationService.Client<MeshTransport>

    func push(_ rec: SettleMedicationExpiryStatusRecord) async throws {
        _ = try await client.simulateIncident(.with {
            $0.details.currencyCode = rec.status
            $0.incidentID = rec.resultStatus
        })
    }
}

/// Sends records to acme.prescriptions.v1.PrescriptionValidationService.
struct SettleMedicationExpiryStatusPrescriptionValidation: SettleMedicationExpiryStatusDestination {
    let client: Acme_Prescriptions_V1_PrescriptionValidationService.Client<MeshTransport>

    func push(_ rec: SettleMedicationExpiryStatusRecord) async throws {
        let request = Acme_Prescriptions_V1_ScorePrescriptionRequest.with {
            $0.details.currencyCode = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scorePrescription(request)
        }
    }
}

/// Passes records to acme.telehealth.v1.TriageWorkflowService.
struct SettleMedicationExpiryStatusTriageWorkflow: SettleMedicationExpiryStatusDestination {
    let client: Acme_Telehealth_V1_TriageWorkflowService.Client<MeshTransport>

    func push(_ rec: SettleMedicationExpiryStatusRecord) async throws {
        _ = try await client.pauseTriageWorkflow(.with {
            $0.triage.triageID = rec.message
            $0.details.initiatedBy = rec.status
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationLifecycleService/ScheduleMedicationExpiry and hands what it keeps to the sink of its kind.
enum SettleMedicationExpiryStatus {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)
        let response = try await reader.scheduleMedicationExpiry(.with { $0.reason = "default-settle-medication-expiry-status" })
        let entry = SettleMedicationExpiryStatusRecord(
            status: Kit.Text.normalize(response.outcome.status),
            resultStatus: response.result.status,
            message: response.outcome.message
        )
        let sinks: [any SettleMedicationExpiryStatusDestination] = [
            SettleMedicationExpiryStatusIncidentCalculation(client: Acme_Itsm_V1_IncidentCalculationService.Client(wrapping: mesh)),
            SettleMedicationExpiryStatusPrescriptionValidation(client: Acme_Prescriptions_V1_PrescriptionValidationService.Client(wrapping: mesh)),
            SettleMedicationExpiryStatusTriageWorkflow(client: Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.push(entry)
        }
    }
}
