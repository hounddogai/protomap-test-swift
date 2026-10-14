import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillCarePlanWorkflowNumber keeps of each SignalCarePlanWorkflow response.
struct BackfillCarePlanWorkflowNumberRecord {
    var number: String
    var status: String
    var notes: String
    var carePlanID: String
}

/// Where BackfillCarePlanWorkflowNumber hands each record.
protocol BackfillCarePlanWorkflowNumberTarget {
    func push(_ rec: BackfillCarePlanWorkflowNumberRecord) async throws
}

/// Sends records to acme.patientapp.v1.CareInboxIntegrationService.
struct BackfillCarePlanWorkflowNumberCareInboxIntegration: BackfillCarePlanWorkflowNumberTarget {
    let client: Acme_Patientapp_V1_CareInboxIntegrationService.Client<MeshTransport>

    func push(_ rec: BackfillCarePlanWorkflowNumberRecord) async throws {
        _ = try await client.testCareInboxConnection(.with {
            $0.careInboxID = rec.carePlanID
            $0.reason = rec.notes
            $0.details.sourceSystem = rec.status
        })
    }
}

/// Sends records to acme.prescriptions.v1.MedicationWorkflowService.
struct BackfillCarePlanWorkflowNumberMedicationWorkflow: BackfillCarePlanWorkflowNumberTarget {
    let client: Acme_Prescriptions_V1_MedicationWorkflowService.Client<MeshTransport>

    func push(_ rec: BackfillCarePlanWorkflowNumberRecord) async throws {
        _ = try await client.inspectMedicationWorkflow(.with {
            $0.medicationID = rec.notes
        })
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionCalculationService.
struct BackfillCarePlanWorkflowNumberPrescriptionCalculation: BackfillCarePlanWorkflowNumberTarget {
    let client: Acme_Prescriptions_V1_PrescriptionCalculationService.Client<MeshTransport>

    func push(_ rec: BackfillCarePlanWorkflowNumberRecord) async throws {
        _ = try await client.quotePrescription(.with {
            $0.prescription.prescriptionID = rec.carePlanID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct BackfillCarePlanWorkflowNumberLogOnly: BackfillCarePlanWorkflowNumberTarget {
    let logger = Logger(label: "acme.backfill-care-plan-workflow-number")

    func push(_ rec: BackfillCarePlanWorkflowNumberRecord) async throws {
        logger.info("No sink for record", metadata: ["number": .string(rec.number)])
    }
}

/// Reads acme.careplans.v1.CarePlanWorkflowService/SignalCarePlanWorkflow and hands what it keeps to the sink of its kind.
enum BackfillCarePlanWorkflowNumber {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Careplans_V1_CarePlanWorkflowService.Client(wrapping: mesh)
        let response = try await origin.signalCarePlanWorkflow(.with { $0.carePlanID = "nightly-backfill-care-plan-workflow-number" })
        let row = BackfillCarePlanWorkflowNumberRecord(
            number: response.carePlan.number,
            status: Kit.Text.normalize(response.outcome.status),
            notes: Kit.Text.normalize(response.carePlan.notes),
            carePlanID: response.carePlan.carePlanID
        )
        try await deliver("medication-workflow", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: BackfillCarePlanWorkflowNumberRecord, _ mesh: MeshClient) async throws {
        var sink: any BackfillCarePlanWorkflowNumberTarget = BackfillCarePlanWorkflowNumberLogOnly()
        switch kind {
        case "care-inbox-integration":
            sink = BackfillCarePlanWorkflowNumberCareInboxIntegration(client: Acme_Patientapp_V1_CareInboxIntegrationService.Client(wrapping: mesh))
        case "medication-workflow":
            sink = BackfillCarePlanWorkflowNumberMedicationWorkflow(client: Acme_Prescriptions_V1_MedicationWorkflowService.Client(wrapping: mesh))
        case "prescription-calculation":
            sink = BackfillCarePlanWorkflowNumberPrescriptionCalculation(client: Acme_Prescriptions_V1_PrescriptionCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.push(rec)
    }
}
