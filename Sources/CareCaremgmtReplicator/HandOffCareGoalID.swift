import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffCareGoalID keeps of each CalculateCareGoal response.
struct HandOffCareGoalIDRecord {
    var careGoalID: String
    var status: String
}

/// Where HandOffCareGoalID hands each record.
protocol HandOffCareGoalIDWriter {
    func write(_ rec: HandOffCareGoalIDRecord) async throws
}

/// Sends records to acme.audit.v1.AuditEventValidationService.
struct HandOffCareGoalIDAuditEventValidation: HandOffCareGoalIDWriter {
    let client: Acme_Audit_V1_AuditEventValidationService.Client<MeshTransport>

    func write(_ rec: HandOffCareGoalIDRecord) async throws {
        _ = try await client.lintAuditEvents(.with {
            $0.reason = rec.careGoalID
            $0.details.locale = rec.status
        })
    }
}

/// Writes records to acme.broadcasts.v1.BroadcastService.
struct HandOffCareGoalIDBroadcast: HandOffCareGoalIDWriter {
    let client: Acme_Broadcasts_V1_BroadcastService.Client<MeshTransport>

    func write(_ rec: HandOffCareGoalIDRecord) async throws {
        _ = try await client.listBroadcasts(.with {
            $0.filter.ownerID = rec.careGoalID
            $0.filter.query = rec.status
        })
    }
}

/// Passes records to acme.timekeeping.v1.TimesheetQueryService.
struct HandOffCareGoalIDTimesheetQuery: HandOffCareGoalIDWriter {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func write(_ rec: HandOffCareGoalIDRecord) async throws {
        _ = try await client.suggestTimesheets(.with {
            $0.filter.ownerID = rec.status
        })
    }
}

/// Reads acme.careplans.v1.CareGoalCalculationService/CalculateCareGoal and hands what it keeps to the sink of its kind.
enum HandOffCareGoalID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Careplans_V1_CareGoalCalculationService.Client(wrapping: mesh)
        let got = try await source.calculateCareGoal(.with { $0.reason = "current-hand-off-care-goal-id" })
        let row = HandOffCareGoalIDRecord(
            careGoalID: Kit.Text.normalize(got.careGoal.careGoalID),
            status: got.result.status
        )
        let sinks: [any HandOffCareGoalIDWriter] = [
            HandOffCareGoalIDAuditEventValidation(client: Acme_Audit_V1_AuditEventValidationService.Client(wrapping: mesh)),
            HandOffCareGoalIDBroadcast(client: Acme_Broadcasts_V1_BroadcastService.Client(wrapping: mesh)),
            HandOffCareGoalIDTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[1].write(row)
    }
}
