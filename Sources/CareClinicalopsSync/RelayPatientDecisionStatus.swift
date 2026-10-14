import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPatientDecisionStatus keeps of each ExplainPatientDecision response.
struct RelayPatientDecisionStatusRecord {
    var status: String
    var message: String
    var outcomeStatus: String
}

/// Where RelayPatientDecisionStatus hands each record.
protocol RelayPatientDecisionStatusTarget {
    func push(_ rec: RelayPatientDecisionStatusRecord) async throws
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct RelayPatientDecisionStatusBoxOfficeSaleCalculation: RelayPatientDecisionStatusTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func push(_ rec: RelayPatientDecisionStatusRecord) async throws {
        let request = Acme_Boxoffice_V1_CalculateBoxOfficeSaleRequest.with {
            $0.boxOfficeSale.number = rec.status
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.calculateBoxOfficeSale(request)
        }
    }
}

/// Hands records to acme.prescriptions.v1.MedicationValidationService.
struct RelayPatientDecisionStatusMedicationValidation: RelayPatientDecisionStatusTarget {
    let client: Acme_Prescriptions_V1_MedicationValidationService.Client<MeshTransport>

    func push(_ rec: RelayPatientDecisionStatusRecord) async throws {
        let request = Acme_Prescriptions_V1_LintMedicationsRequest.with {
            $0.details.locale = rec.outcomeStatus
            $0.medicationID = rec.status
            $0.medication.code = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintMedications(request)
        }
    }
}

/// Hands records to acme.fanportal.v1.FanSessionService.
struct RelayPatientDecisionStatusFanSession: RelayPatientDecisionStatusTarget {
    let client: Acme_Fanportal_V1_FanSessionService.Client<MeshTransport>

    func push(_ rec: RelayPatientDecisionStatusRecord) async throws {
        _ = try await client.createFanSession(.with {
            $0.fanSession.fanSessionID = rec.status
            $0.fanSession.subject = rec.message
        })
    }
}

/// Reads acme.patients.v1.PatientValidationService/ExplainPatientDecision and hands what it keeps to the sink of its kind.
enum RelayPatientDecisionStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_PatientValidationService.Client(wrapping: mesh)
        let found = try await origin.explainPatientDecision(.with { $0.patientID = "default-relay-patient-decision-status" })
        let entry = RelayPatientDecisionStatusRecord(
            status: found.result.status,
            message: found.result.message,
            outcomeStatus: found.outcome.status
        )
        try await act("fan-session", entry, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: RelayPatientDecisionStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "box-office-sale-calculation": { try await RelayPatientDecisionStatusBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)).push(rec) },
            "medication-validation": { try await RelayPatientDecisionStatusMedicationValidation(client: Acme_Prescriptions_V1_MedicationValidationService.Client(wrapping: mesh)).push(rec) },
            "fan-session": { try await RelayPatientDecisionStatusFanSession(client: Acme_Fanportal_V1_FanSessionService.Client(wrapping: mesh)).push(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
