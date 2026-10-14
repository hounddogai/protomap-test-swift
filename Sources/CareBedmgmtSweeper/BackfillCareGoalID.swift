import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillCareGoalID keeps of each SimulateCareGoal response.
struct BackfillCareGoalIDRecord {
    var careGoalID: String
    var subject: String
    var currencyCode: String
    var status: String
}

/// Where BackfillCareGoalID hands each record.
protocol BackfillCareGoalIDWriter {
    func send(_ rec: BackfillCareGoalIDRecord) async throws
}

/// Writes records to acme.treasury.v1.CashPositionService.
struct BackfillCareGoalIDCashPosition: BackfillCareGoalIDWriter {
    let client: Acme_Treasury_V1_CashPositionService.Client<MeshTransport>

    func send(_ rec: BackfillCareGoalIDRecord) async throws {
        _ = try await client.cloneCashPosition(.with {
            $0.cashPosition.currencyCode = rec.currencyCode
            $0.requestID = rec.status
        })
    }
}

/// Hands records to acme.identity.v1.UserQueryService.
struct BackfillCareGoalIDUserQuery: BackfillCareGoalIDWriter {
    let client: Acme_Identity_V1_UserQueryService.Client<MeshTransport>

    func send(_ rec: BackfillCareGoalIDRecord) async throws {
        let request = Acme_Identity_V1_SuggestUsersRequest.with {
            $0.filter.query = rec.careGoalID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestUsers(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteValidationService.
struct BackfillCareGoalIDVisitNoteValidation: BackfillCareGoalIDWriter {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func send(_ rec: BackfillCareGoalIDRecord) async throws {
        _ = try await client.scoreVisitNote(.with {
            $0.details.currencyCode = rec.currencyCode
            $0.visitNoteID = rec.careGoalID
            $0.visitNote.number = rec.subject
        })
    }
}

/// Sends records to acme.timekeeping.v1.TimesheetQueryService.
struct BackfillCareGoalIDTimesheetQuery: BackfillCareGoalIDWriter {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func send(_ rec: BackfillCareGoalIDRecord) async throws {
        _ = try await client.countTimesheets(.with {
            $0.page.pageToken = rec.currencyCode
            $0.filter.region = rec.careGoalID
            $0.filter.query = rec.status
        })
    }
}

/// Reads acme.careplans.v1.CareGoalCalculationService/SimulateCareGoal and hands what it keeps to the sink of its kind.
enum BackfillCareGoalID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)
        let response = try await reader.simulateCareGoal(.with { $0.careGoalID = "default-backfill-care-goal-id" })
        let record = BackfillCareGoalIDRecord(
            careGoalID: response.careGoal.careGoalID,
            subject: response.careGoal.subject,
            currencyCode: response.breakdown.currencyCode,
            status: response.result.status
        )
        let sinks: [any BackfillCareGoalIDWriter] = [
            BackfillCareGoalIDCashPosition(client: Acme_Treasury_V1_CashPositionService.Client(wrapping: mesh)),
            BackfillCareGoalIDUserQuery(client: Acme_Identity_V1_UserQueryService.Client(wrapping: mesh)),
            BackfillCareGoalIDVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)),
            BackfillCareGoalIDTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[0].send(record)
    }
}
