import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagateMedicalRecordWorkflowID keeps of each SignalMedicalRecordWorkflow response.
struct PropagateMedicalRecordWorkflowIDRecord {
    var correlationID: String
    var notes: String
    var referenceID: String
}

/// Where PropagateMedicalRecordWorkflowID hands each record.
protocol PropagateMedicalRecordWorkflowIDDestination {
    func send(_ rec: PropagateMedicalRecordWorkflowIDRecord) async throws
}

/// Writes records to acme.featureflags.v1.FeatureFlagValidationService.
struct PropagateMedicalRecordWorkflowIDFeatureFlagValidation: PropagateMedicalRecordWorkflowIDDestination {
    let client: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordWorkflowIDRecord) async throws {
        let request = Acme_Featureflags_V1_LintFeatureFlagsRequest.with {
            $0.details.locale = rec.referenceID
            $0.featureFlag.featureFlagID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintFeatureFlags(request)
        }
    }
}

/// Passes records to acme.careplans.v1.CarePlanCalculationService.
struct PropagateMedicalRecordWorkflowIDCarePlanCalculation: PropagateMedicalRecordWorkflowIDDestination {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordWorkflowIDRecord) async throws {
        _ = try await client.recalculateCarePlans(.with {
            $0.carePlan.notes = rec.referenceID
        })
    }
}

/// Hands records to acme.shows.v1.ShowCalculationService.
struct PropagateMedicalRecordWorkflowIDShowCalculation: PropagateMedicalRecordWorkflowIDDestination {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordWorkflowIDRecord) async throws {
        let request = Acme_Shows_V1_QuoteShowRequest.with {
            $0.show.title = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteShow(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionSyncService.
struct PropagateMedicalRecordWorkflowIDPrescriptionSync: PropagateMedicalRecordWorkflowIDDestination {
    let client: Acme_Prescriptions_V1_PrescriptionSyncService.Client<MeshTransport>

    func send(_ rec: PropagateMedicalRecordWorkflowIDRecord) async throws {
        let request = Acme_Prescriptions_V1_ResolvePrescriptionConflictRequest.with {
            $0.prescription.prescriptionID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.resolvePrescriptionConflict(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PropagateMedicalRecordWorkflowIDLogOnly: PropagateMedicalRecordWorkflowIDDestination {
    let logger = Logger(label: "acme.propagate-medical-record-workflow-id")

    func send(_ rec: PropagateMedicalRecordWorkflowIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.patients.v1.MedicalRecordWorkflowService/SignalMedicalRecordWorkflow and hands what it keeps to the sink of its kind.
enum PropagateMedicalRecordWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_MedicalRecordWorkflowService.Client(wrapping: mesh)
        let response = try await origin.signalMedicalRecordWorkflow(.with { $0.medicalRecordID = "current-propagate-medical-record-workflow-id" })
        let row = PropagateMedicalRecordWorkflowIDRecord(
            correlationID: response.result.correlationID,
            notes: response.medicalRecord.notes,
            referenceID: response.outcome.referenceID
        )
        try await deliver("feature-flag-validation", row, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: PropagateMedicalRecordWorkflowIDRecord, _ mesh: MeshClient) async throws {
        var sink: any PropagateMedicalRecordWorkflowIDDestination = PropagateMedicalRecordWorkflowIDLogOnly()
        switch kind {
        case "feature-flag-validation":
            sink = PropagateMedicalRecordWorkflowIDFeatureFlagValidation(client: Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh))
        case "care-plan-calculation":
            sink = PropagateMedicalRecordWorkflowIDCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh))
        case "show-calculation":
            sink = PropagateMedicalRecordWorkflowIDShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh))
        case "prescription-sync":
            sink = PropagateMedicalRecordWorkflowIDPrescriptionSync(client: Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
