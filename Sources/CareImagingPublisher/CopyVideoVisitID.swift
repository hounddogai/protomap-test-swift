import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyVideoVisitID keeps of each ValidateVideoVisit response.
struct CopyVideoVisitIDRecord {
    var correlationID: String
    var status: String
    var resultStatus: String
    var message: String
}

/// Where CopyVideoVisitID hands each record.
protocol CopyVideoVisitIDSink {
    func apply(_ rec: CopyVideoVisitIDRecord) async throws
}

/// Hands records to acme.budgeting.v1.BudgetQueryService.
struct CopyVideoVisitIDBudgetQuery: CopyVideoVisitIDSink {
    let client: Acme_Budgeting_V1_BudgetQueryService.Client<MeshTransport>

    func apply(_ rec: CopyVideoVisitIDRecord) async throws {
        let request = Acme_Budgeting_V1_BrowseBudgetsRequest.with {
            $0.orderBy = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseBudgets(request)
        }
    }
}

/// Passes records to acme.appointments.v1.AppointmentApprovalService.
struct CopyVideoVisitIDAppointmentApproval: CopyVideoVisitIDSink {
    let client: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>

    func apply(_ rec: CopyVideoVisitIDRecord) async throws {
        let request = Acme_Appointments_V1_GetAppointmentApprovalStatusRequest.with {
            $0.appointmentID = rec.resultStatus
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getAppointmentApprovalStatus(request)
        }
    }
}

/// Sends records to acme.fanportal.v1.FanSessionQueryService.
struct CopyVideoVisitIDFanSessionQuery: CopyVideoVisitIDSink {
    let client: Acme_Fanportal_V1_FanSessionQueryService.Client<MeshTransport>

    func apply(_ rec: CopyVideoVisitIDRecord) async throws {
        _ = try await client.findFanSessions(.with {
            $0.filter.query = rec.resultStatus
            $0.orderBy = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CopyVideoVisitIDLogOnly: CopyVideoVisitIDSink {
    let logger = Logger(label: "acme.copy-video-visit-id")

    func apply(_ rec: CopyVideoVisitIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitValidationService/ValidateVideoVisit and hands what it keeps to the sink of its kind.
enum CopyVideoVisitID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)
        let reply = try await origin.validateVideoVisit(.with { $0.reason = "nightly-copy-video-visit-id" })
        let record = CopyVideoVisitIDRecord(
            correlationID: reply.result.correlationID,
            status: reply.outcome.status,
            resultStatus: reply.result.status,
            message: reply.result.message
        )
        try await deliver("budget-query", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CopyVideoVisitIDRecord, _ mesh: MeshClient) async throws {
        var sink: any CopyVideoVisitIDSink = CopyVideoVisitIDLogOnly()
        switch kind {
        case "budget-query":
            sink = CopyVideoVisitIDBudgetQuery(client: Acme_Budgeting_V1_BudgetQueryService.Client(wrapping: mesh))
        case "appointment-approval":
            sink = CopyVideoVisitIDAppointmentApproval(client: Acme_Appointments_V1_AppointmentApprovalService.Client(wrapping: mesh))
        case "fan-session-query":
            sink = CopyVideoVisitIDFanSessionQuery(client: Acme_Fanportal_V1_FanSessionQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
