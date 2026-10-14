import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardPrescriptionWorkflowID keeps of each AdvancePrescriptionWorkflow response.
struct ForwardPrescriptionWorkflowIDRecord {
    var prescriptionID: String
    var number: String
    var status: String
    var message: String
}

/// Where ForwardPrescriptionWorkflowID hands each record.
protocol ForwardPrescriptionWorkflowIDDestination {
    func deliver(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws
}

/// Sends records to acme.yards.v1.YardCalculationService.
struct ForwardPrescriptionWorkflowIDYardCalculation: ForwardPrescriptionWorkflowIDDestination {
    let client: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>

    func deliver(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.estimateYard(.with {
            $0.yard.yardID = rec.status
            $0.details.currencyCode = rec.message
            $0.reason = rec.prescriptionID
        })
    }
}

/// Sends records to acme.telehealth.v1.VisitNoteValidationService.
struct ForwardPrescriptionWorkflowIDVisitNoteValidation: ForwardPrescriptionWorkflowIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func deliver(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.scoreVisitNote(.with {
            $0.visitNoteID = rec.prescriptionID
            $0.reason = rec.status
            $0.details.currencyCode = rec.message
        })
    }
}

/// Sends records to acme.careplans.v1.VitalApprovalService.
struct ForwardPrescriptionWorkflowIDVitalApproval: ForwardPrescriptionWorkflowIDDestination {
    let client: Acme_Careplans_V1_VitalApprovalService.Client<MeshTransport>

    func deliver(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.commentVitalApproval(.with {
            $0.vital.kind = rec.prescriptionID
            $0.details.approverEmail = rec.message
        })
    }
}

/// Sends records to acme.recruiting.v1.JobOpeningService.
struct ForwardPrescriptionWorkflowIDJobOpening: ForwardPrescriptionWorkflowIDDestination {
    let client: Acme_Recruiting_V1_JobOpeningService.Client<MeshTransport>

    func deliver(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        _ = try await client.updateJobOpening(.with {
            $0.jobOpening.notes = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct ForwardPrescriptionWorkflowIDLogOnly: ForwardPrescriptionWorkflowIDDestination {
    let logger = Logger(label: "acme.forward-prescription-workflow-id")

    func deliver(_ rec: ForwardPrescriptionWorkflowIDRecord) async throws {
        logger.info("No sink for record", metadata: ["prescriptionID": .string(rec.prescriptionID)])
    }
}

/// Reads acme.prescriptions.v1.PrescriptionWorkflowService/AdvancePrescriptionWorkflow and hands what it keeps to the sink of its kind.
enum ForwardPrescriptionWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)
        let got = try await upstream.advancePrescriptionWorkflow(.with { $0.prescriptionID = "live-forward-prescription-workflow-id" })
        let rec = ForwardPrescriptionWorkflowIDRecord(
            prescriptionID: got.prescription.prescriptionID,
            number: got.prescription.number,
            status: Kit.Text.normalize(got.outcome.status),
            message: Kit.Text.normalize(got.outcome.message)
        )
        try await dispatch("visit-note-validation", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: ForwardPrescriptionWorkflowIDRecord, _ mesh: MeshClient) async throws {
        var write: (ForwardPrescriptionWorkflowIDRecord) async throws -> Void = ForwardPrescriptionWorkflowIDLogOnly().deliver
        switch kind {
        case "yard-calculation":
            write = ForwardPrescriptionWorkflowIDYardCalculation(client: Acme_Yards_V1_YardCalculationService.Client(wrapping: mesh)).deliver
        case "visit-note-validation":
            write = ForwardPrescriptionWorkflowIDVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)).deliver
        case "vital-approval":
            write = ForwardPrescriptionWorkflowIDVitalApproval(client: Acme_Careplans_V1_VitalApprovalService.Client(wrapping: mesh)).deliver
        case "job-opening":
            write = ForwardPrescriptionWorkflowIDJobOpening(client: Acme_Recruiting_V1_JobOpeningService.Client(wrapping: mesh)).deliver
        default:
            break
        }
        try await write(rec)
    }
}
