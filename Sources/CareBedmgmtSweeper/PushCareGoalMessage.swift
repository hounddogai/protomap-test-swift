import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushCareGoalMessage keeps of each SubmitCareGoal response.
struct PushCareGoalMessageRecord {
    var message: String
    var status: String
    var outcomeMessage: String
}

/// Where PushCareGoalMessage hands each record.
protocol PushCareGoalMessageWriter {
    func write(_ rec: PushCareGoalMessageRecord) async throws
}

/// Sends records to acme.venues.v1.VenueValidationService.
struct PushCareGoalMessageVenueValidation: PushCareGoalMessageWriter {
    let client: Acme_Venues_V1_VenueValidationService.Client<MeshTransport>

    func write(_ rec: PushCareGoalMessageRecord) async throws {
        _ = try await client.scoreVenue(.with {
            $0.venue.venueID = rec.status
            $0.venue.code = rec.message
        })
    }
}

/// Writes records to acme.lending.v1.LoanApplicationCalculationService.
struct PushCareGoalMessageLoanApplicationCalculation: PushCareGoalMessageWriter {
    let client: Acme_Lending_V1_LoanApplicationCalculationService.Client<MeshTransport>

    func write(_ rec: PushCareGoalMessageRecord) async throws {
        _ = try await client.simulateLoanApplication(.with {
            $0.loanApplication.number = rec.message
            $0.loanApplication.loanApplicationID = rec.status
        })
    }
}

/// Passes records to acme.telehealth.v1.VideoVisitApprovalService.
struct PushCareGoalMessageVideoVisitApproval: PushCareGoalMessageWriter {
    let client: Acme_Telehealth_V1_VideoVisitApprovalService.Client<MeshTransport>

    func write(_ rec: PushCareGoalMessageRecord) async throws {
        let request = Acme_Telehealth_V1_CommentVideoVisitApprovalRequest.with {
            $0.details.comment = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.commentVideoVisitApproval(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct PushCareGoalMessageLogOnly: PushCareGoalMessageWriter {
    let logger = Logger(label: "acme.push-care-goal-message")

    func write(_ rec: PushCareGoalMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.careplans.v1.CareGoalApprovalService/SubmitCareGoal and hands what it keeps to the sink of its kind.
enum PushCareGoalMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CareGoalApprovalService.Client(wrapping: mesh)
        let response = try await source.submitCareGoal(.with { $0.careGoalID = "primary-push-care-goal-message" })
        let record = PushCareGoalMessageRecord(
            message: response.result.message,
            status: response.outcome.status,
            outcomeMessage: response.outcome.message
        )
        try await dispatch("loan-application-calculation", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: PushCareGoalMessageRecord, _ mesh: MeshClient) async throws {
        var write: (PushCareGoalMessageRecord) async throws -> Void = PushCareGoalMessageLogOnly().write
        switch kind {
        case "venue-validation":
            write = PushCareGoalMessageVenueValidation(client: Acme_Venues_V1_VenueValidationService.Client(wrapping: mesh)).write
        case "loan-application-calculation":
            write = PushCareGoalMessageLoanApplicationCalculation(client: Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh)).write
        case "video-visit-approval":
            write = PushCareGoalMessageVideoVisitApproval(client: Acme_Telehealth_V1_VideoVisitApprovalService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
