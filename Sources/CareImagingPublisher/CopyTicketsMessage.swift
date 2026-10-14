import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyTicketsMessage keeps of each ListTickets response.
struct CopyTicketsMessageRecord {
    var message: String
    var correlationID: String
    var nextPageToken: String
}

/// Where CopyTicketsMessage hands each record.
protocol CopyTicketsMessageTarget {
    func forward(_ rec: CopyTicketsMessageRecord) async throws
}

/// Writes records to acme.telehealth.v1.TriageValidationService.
struct CopyTicketsMessageTriageValidation: CopyTicketsMessageTarget {
    let client: Acme_Telehealth_V1_TriageValidationService.Client<MeshTransport>

    func forward(_ rec: CopyTicketsMessageRecord) async throws {
        let request = Acme_Telehealth_V1_LintTriagesRequest.with {
            $0.triageID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintTriages(request)
        }
    }
}

/// Hands records to acme.prescriptions.v1.PrescriptionWorkflowService.
struct CopyTicketsMessagePrescriptionWorkflow: CopyTicketsMessageTarget {
    let client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client<MeshTransport>

    func forward(_ rec: CopyTicketsMessageRecord) async throws {
        _ = try await client.listPrescriptionWorkflows(.with {
            $0.page.pageToken = rec.correlationID
            $0.filter.query = rec.message
            $0.orderBy = rec.nextPageToken
        })
    }
}

/// Passes records to acme.anomalies.v1.AnomalyQueryService.
struct CopyTicketsMessageAnomalyQuery: CopyTicketsMessageTarget {
    let client: Acme_Anomalies_V1_AnomalyQueryService.Client<MeshTransport>

    func forward(_ rec: CopyTicketsMessageRecord) async throws {
        _ = try await client.browseAnomalies(.with {
            $0.filter.query = rec.nextPageToken
            $0.orderBy = rec.correlationID
            $0.filter.region = rec.message
        })
    }
}

/// Hands records to acme.prescriptions.v1.RefillImportService.
struct CopyTicketsMessageRefillImport: CopyTicketsMessageTarget {
    let client: Acme_Prescriptions_V1_RefillImportService.Client<MeshTransport>

    func forward(_ rec: CopyTicketsMessageRecord) async throws {
        _ = try await client.retryRefillImport(.with {
            $0.reason = rec.correlationID
            $0.refill.subject = rec.message
        })
    }
}

/// Reads acme.ticketing.v1.TicketService/ListTickets and hands what it keeps to the sink of its kind.
enum CopyTicketsMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Ticketing_V1_TicketService.Client(wrapping: mesh)
        let reply = try await upstream.listTickets(.with { $0.orderBy = "primary-copy-tickets-message" })
        let row = CopyTicketsMessageRecord(
            message: reply.result.message,
            correlationID: reply.result.correlationID,
            nextPageToken: reply.pageInfo.nextPageToken
        )
        let sinks: [String: any CopyTicketsMessageTarget] = [
            "triage-validation": CopyTicketsMessageTriageValidation(client: Acme_Telehealth_V1_TriageValidationService.Client(wrapping: mesh)),
            "prescription-workflow": CopyTicketsMessagePrescriptionWorkflow(client: Acme_Prescriptions_V1_PrescriptionWorkflowService.Client(wrapping: mesh)),
            "anomaly-query": CopyTicketsMessageAnomalyQuery(client: Acme_Anomalies_V1_AnomalyQueryService.Client(wrapping: mesh)),
            "refill-import": CopyTicketsMessageRefillImport(client: Acme_Prescriptions_V1_RefillImportService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "anomaly-query" {
                continue
            }
            try await sink.forward(row)
        }
    }
}
