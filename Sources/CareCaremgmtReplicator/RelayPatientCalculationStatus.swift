import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayPatientCalculationStatus keeps of each ExplainPatientCalculation response.
struct RelayPatientCalculationStatusRecord {
    var status: String
    var correlationID: String
}

/// Where RelayPatientCalculationStatus hands each record.
protocol RelayPatientCalculationStatusWriter {
    func forward(_ rec: RelayPatientCalculationStatusRecord) async throws
}

/// Writes records to acme.patientapp.v1.PatientHomeWorkflowService.
struct RelayPatientCalculationStatusPatientHomeWorkflow: RelayPatientCalculationStatusWriter {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func forward(_ rec: RelayPatientCalculationStatusRecord) async throws {
        _ = try await client.pausePatientHomeWorkflow(.with {
            $0.details.step = rec.correlationID
        })
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteCalculationService.
struct RelayPatientCalculationStatusVisitNoteCalculation: RelayPatientCalculationStatusWriter {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func forward(_ rec: RelayPatientCalculationStatusRecord) async throws {
        _ = try await client.simulateVisitNote(.with {
            $0.visitNote.number = rec.correlationID
            $0.details.currencyCode = rec.status
        })
    }
}

/// Passes records to acme.careplans.v1.CarePlanLifecycleService.
struct RelayPatientCalculationStatusCarePlanLifecycle: RelayPatientCalculationStatusWriter {
    let client: Acme_Careplans_V1_CarePlanLifecycleService.Client<MeshTransport>

    func forward(_ rec: RelayPatientCalculationStatusRecord) async throws {
        _ = try await client.suspendCarePlan(.with {
            $0.carePlanID = rec.status
            $0.reason = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.PatientCalculationService/ExplainPatientCalculation and hands what it keeps to the sink of its kind.
enum RelayPatientCalculationStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_PatientCalculationService.Client(wrapping: mesh)
        let found = try await origin.explainPatientCalculation(.with { $0.reason = "main-relay-patient-calculation-status" })
        let rec = RelayPatientCalculationStatusRecord(
            status: Kit.Text.normalize(found.result.status),
            correlationID: found.result.correlationID
        )
        let sinks: [String: any RelayPatientCalculationStatusWriter] = [
            "patient-home-workflow": RelayPatientCalculationStatusPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            "visit-note-calculation": RelayPatientCalculationStatusVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)),
            "care-plan-lifecycle": RelayPatientCalculationStatusCarePlanLifecycle(client: Acme_Careplans_V1_CarePlanLifecycleService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["RELAY_PATIENT_CALCULATION_STATUS_TARGET"] ?? ""] else {
            return
        }
        try await sink.forward(rec)
    }
}
