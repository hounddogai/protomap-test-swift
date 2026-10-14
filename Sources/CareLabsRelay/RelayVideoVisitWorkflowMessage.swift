import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayVideoVisitWorkflowMessage keeps of each SignalVideoVisitWorkflow response.
struct RelayVideoVisitWorkflowMessageRecord {
    var message: String
    var title: String
    var status: String
    var outcomeMessage: String
}

/// Where RelayVideoVisitWorkflowMessage hands each record.
protocol RelayVideoVisitWorkflowMessageSink {
    func push(_ rec: RelayVideoVisitWorkflowMessageRecord) async throws
}

/// Hands records to acme.seating.v1.SeatMapCalculationService.
struct RelayVideoVisitWorkflowMessageSeatMapCalculation: RelayVideoVisitWorkflowMessageSink {
    let client: Acme_Seating_V1_SeatMapCalculationService.Client<MeshTransport>

    func push(_ rec: RelayVideoVisitWorkflowMessageRecord) async throws {
        _ = try await client.explainSeatMapCalculation(.with {
            $0.seatMap.name = rec.title
            $0.seatMapID = rec.outcomeMessage
            $0.seatMap.parentID = rec.message
        })
    }
}

/// Hands records to acme.prescriptions.v1.MedicationReportingService.
struct RelayVideoVisitWorkflowMessageMedicationReporting: RelayVideoVisitWorkflowMessageSink {
    let client: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>

    func push(_ rec: RelayVideoVisitWorkflowMessageRecord) async throws {
        let request = Acme_Prescriptions_V1_ScheduleMedicationReportRequest.with {
            $0.reason = rec.title
            $0.details.format = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scheduleMedicationReport(request)
        }
    }
}

/// Passes records to acme.appointments.v1.ProviderApprovalService.
struct RelayVideoVisitWorkflowMessageProviderApproval: RelayVideoVisitWorkflowMessageSink {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func push(_ rec: RelayVideoVisitWorkflowMessageRecord) async throws {
        let request = Acme_Appointments_V1_EscalateProviderRequest.with {
            $0.provider.providerID = rec.message
            $0.details.comment = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.escalateProvider(request)
        }
    }
}

/// Writes records to acme.authorization.v1.AccessPolicyQueryService.
struct RelayVideoVisitWorkflowMessageAccessPolicyQuery: RelayVideoVisitWorkflowMessageSink {
    let client: Acme_Authorization_V1_AccessPolicyQueryService.Client<MeshTransport>

    func push(_ rec: RelayVideoVisitWorkflowMessageRecord) async throws {
        _ = try await client.findAccessPolicies(.with {
            $0.filter.ownerID = rec.title
            $0.filter.region = rec.status
        })
    }
}

/// Reads acme.telehealth.v1.VideoVisitWorkflowService/SignalVideoVisitWorkflow and hands what it keeps to the sink of its kind.
enum RelayVideoVisitWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Telehealth_V1_VideoVisitWorkflowService.Client(wrapping: mesh)
        let response = try await origin.signalVideoVisitWorkflow(.with { $0.reason = "current-relay-video-visit-workflow-message" })
        let rec = RelayVideoVisitWorkflowMessageRecord(
            message: response.result.message,
            title: Kit.Text.normalize(response.videoVisit.title),
            status: response.outcome.status,
            outcomeMessage: Kit.Text.normalize(response.outcome.message)
        )
        let sinks: [any RelayVideoVisitWorkflowMessageSink] = [
            RelayVideoVisitWorkflowMessageSeatMapCalculation(client: Acme_Seating_V1_SeatMapCalculationService.Client(wrapping: mesh)),
            RelayVideoVisitWorkflowMessageMedicationReporting(client: Acme_Prescriptions_V1_MedicationReportingService.Client(wrapping: mesh)),
            RelayVideoVisitWorkflowMessageProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)),
            RelayVideoVisitWorkflowMessageAccessPolicyQuery(client: Acme_Authorization_V1_AccessPolicyQueryService.Client(wrapping: mesh)),
        ]
        try await sinks[1].push(rec)
    }
}
