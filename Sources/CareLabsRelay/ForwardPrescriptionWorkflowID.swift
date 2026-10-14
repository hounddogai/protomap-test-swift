import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPrescriptionWorkflowID keeps of each StartPrescriptionWorkflow response.
struct ForwardPrescriptionWorkflowIDRecord {
    var correlationID: String
    var prescriptionID: String
    var status: String
    var notes: String
}

/// Where ForwardPrescriptionWorkflowID hands each record.
protocol ForwardPrescriptionWorkflowIDDestination {
    func forward(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws
}

/// Sends records to acme.concessions.v1.ConcessionStandService.
struct ForwardPrescriptionWorkflowIDConcessionStand: ForwardPrescriptionWorkflowIDDestination {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func forward(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.updateConcessionStand(.with {
            $0.concessionStand.code = rec.status
        })
    }
}

/// Hands records to acme.featureflags.v1.FeatureFlagValidationService.
struct ForwardPrescriptionWorkflowIDFeatureFlagValidation: ForwardPrescriptionWorkflowIDDestination {
    let client: Acme_Featureflags_V1_FeatureFlagValidationService.Client<MeshTransport>

    func forward(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.checkFeatureFlagEligibility(.with {
            $0.featureFlag.description_p = rec.notes
            $0.details.locale = rec.correlationID
            $0.featureFlagID = rec.prescriptionID
        })
    }
}

/// Reads acme.prescriptions.v1.PrescriptionWorkflowService/StartPrescriptionWorkflow and hands what it keeps to the sink of its kind.
enum ForwardPrescriptionWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)
        let got = try await origin.startPrescriptionWorkflow(.with { $0.prescriptionID = "default-forward-prescription-workflow-id" })
        let record = ForwardPrescriptionWorkflowIDRecord(
            correlationID: got.result.correlationID,
            prescriptionID: Kit.Text.normalize(got.prescription.prescriptionID),
            status: got.result.status,
            notes: got.prescription.notes
        )
        let sinks: [any ForwardPrescriptionWorkflowIDDestination] = [
            ForwardPrescriptionWorkflowIDConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)),
            ForwardPrescriptionWorkflowIDFeatureFlagValidation(client: Acme_Featureflags_V1_FeatureFlagValidationService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.forward(record)
        }
    }
}
