import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteProviderWorkflowMessage keeps of each RetryProviderWorkflow response.
struct RouteProviderWorkflowMessageRecord {
    var message: String
    var referenceID: String
}

/// Where RouteProviderWorkflowMessage hands each record.
protocol RouteProviderWorkflowMessageSink {
    func send(_ rec: RouteProviderWorkflowMessageRecord) async throws
}

/// Hands records to acme.itsm.v1.IncidentQueryService.
struct RouteProviderWorkflowMessageIncidentQuery: RouteProviderWorkflowMessageSink {
    let client: Acme_Itsm_V1_IncidentQueryService.Client<MeshTransport>

    func send(_ rec: RouteProviderWorkflowMessageRecord) async throws {
        _ = try await client.lookupIncident(.with {
            $0.incidentID = rec.message
        })
    }
}

/// Writes records to acme.telehealth.v1.TriageApprovalService.
struct RouteProviderWorkflowMessageTriageApproval: RouteProviderWorkflowMessageSink {
    let client: Acme_Telehealth_V1_TriageApprovalService.Client<MeshTransport>

    func send(_ rec: RouteProviderWorkflowMessageRecord) async throws {
        _ = try await client.approveTriage(.with {
            $0.triageID = rec.referenceID
            $0.triage.subject = rec.message
        })
    }
}

/// Writes records to acme.performers.v1.PerformerQueryService.
struct RouteProviderWorkflowMessagePerformerQuery: RouteProviderWorkflowMessageSink {
    let client: Acme_Performers_V1_PerformerQueryService.Client<MeshTransport>

    func send(_ rec: RouteProviderWorkflowMessageRecord) async throws {
        _ = try await client.suggestPerformers(.with {
            $0.orderBy = rec.referenceID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RouteProviderWorkflowMessageLogOnly: RouteProviderWorkflowMessageSink {
    let logger = Logger(label: "acme.route-provider-workflow-message")

    func send(_ rec: RouteProviderWorkflowMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.appointments.v1.ProviderWorkflowService/RetryProviderWorkflow and hands what it keeps to the sink of its kind.
enum RouteProviderWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Appointments_V1_ProviderWorkflowService.Client(wrapping: mesh)
        let found = try await source.retryProviderWorkflow(.with { $0.providerID = "current-route-provider-workflow-message" })
        let record = RouteProviderWorkflowMessageRecord(
            message: found.result.message,
            referenceID: found.outcome.referenceID
        )
        try await deliver("incident-query", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RouteProviderWorkflowMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any RouteProviderWorkflowMessageSink = RouteProviderWorkflowMessageLogOnly()
        switch kind {
        case "incident-query":
            sink = RouteProviderWorkflowMessageIncidentQuery(client: Acme_Itsm_V1_IncidentQueryService.Client(wrapping: mesh))
        case "triage-approval":
            sink = RouteProviderWorkflowMessageTriageApproval(client: Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: mesh))
        case "performer-query":
            sink = RouteProviderWorkflowMessagePerformerQuery(client: Acme_Performers_V1_PerformerQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
