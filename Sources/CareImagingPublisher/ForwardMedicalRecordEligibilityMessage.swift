import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ForwardMedicalRecordEligibilityMessage keeps of each CheckMedicalRecordEligibility response.
struct ForwardMedicalRecordEligibilityMessageRecord {
    var message: String
    var correlationID: String
    var outcomeMessage: String
    var number: String
}

/// Where ForwardMedicalRecordEligibilityMessage hands each record.
protocol ForwardMedicalRecordEligibilityMessageWriter {
    func apply(_ rec: ForwardMedicalRecordEligibilityMessageRecord) async throws
}

/// Sends records to acme.pipelines.v1.PipelineCalculationService.
struct ForwardMedicalRecordEligibilityMessagePipelineCalculation: ForwardMedicalRecordEligibilityMessageWriter {
    let client: Acme_Pipelines_V1_PipelineCalculationService.Client<MeshTransport>

    func apply(_ rec: ForwardMedicalRecordEligibilityMessageRecord) async throws {
        _ = try await client.getPipelineRates(.with {
            $0.pipelineID = rec.message
        })
    }
}

/// Passes records to acme.venues.v1.VenueValidationService.
struct ForwardMedicalRecordEligibilityMessageVenueValidation: ForwardMedicalRecordEligibilityMessageWriter {
    let client: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    func apply(_ rec: ForwardMedicalRecordEligibilityMessageRecord) async throws {
        let request = Acme_Venues_V1_NormalizeVenueRequest.with {
            $0.venueID = rec.outcomeMessage
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.normalizeVenue(request)
        }
    }
}

/// Passes records to acme.budgeting.v1.BudgetQueryService.
struct ForwardMedicalRecordEligibilityMessageBudgetQuery: ForwardMedicalRecordEligibilityMessageWriter {
    let client: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>

    func apply(_ rec: ForwardMedicalRecordEligibilityMessageRecord) async throws {
        _ = try await client.peekBudget(.with {
            $0.budgetID = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordValidationService/CheckMedicalRecordEligibility and hands what it keeps to the sink of its kind.
enum ForwardMedicalRecordEligibilityMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh)
        let found = try await source.checkMedicalRecordEligibility(.with { $0.medicalRecordID = "primary-forward-medical-record-eligibility-message" })
        let rec = ForwardMedicalRecordEligibilityMessageRecord(
            message: found.result.message,
            correlationID: found.result.correlationID,
            outcomeMessage: found.outcome.message,
            number: found.medicalRecord.number
        )
        let sinks: [String: any ForwardMedicalRecordEligibilityMessageWriter] = [
            "pipeline-calculation": ForwardMedicalRecordEligibilityMessagePipelineCalculation(client: Acme_Pipelines_V1_PipelineCalculationService.Client(wrapping: mesh)),
            "venue-validation": ForwardMedicalRecordEligibilityMessageVenueValidation(client: Acme_Venues_V1_VenueValidationService.Client(wrapping: mesh)),
            "budget-query": ForwardMedicalRecordEligibilityMessageBudgetQuery(client: Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["FORWARD_MEDICAL_RECORD_ELIGIBILITY_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.apply(rec)
    }
}
