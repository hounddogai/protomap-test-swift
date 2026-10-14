import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyRefillWorkflowStatus keeps of each SignalRefillWorkflow response.
struct CopyRefillWorkflowStatusRecord {
    var status: String
    var refillID: String
    var message: String
    var resultStatus: String
}

/// Where CopyRefillWorkflowStatus hands each record.
protocol CopyRefillWorkflowStatusDestination {
    func deliver(_ rec: CopyRefillWorkflowStatusRecord) async throws
}

/// Passes records to acme.itsm.v1.IncidentQueryService.
struct CopyRefillWorkflowStatusIncidentQuery: CopyRefillWorkflowStatusDestination {
    let client: Acme_Itsm_V1_IncidentQueryService.Client<MeshTransport>

    func deliver(_ rec: CopyRefillWorkflowStatusRecord) async throws {
        let request = Acme_Itsm_V1_SuggestIncidentsRequest.with {
            $0.page.pageToken = rec.message
            $0.filter.region = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestIncidents(request)
        }
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteCalculationService.
struct CopyRefillWorkflowStatusVisitNoteCalculation: CopyRefillWorkflowStatusDestination {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func deliver(_ rec: CopyRefillWorkflowStatusRecord) async throws {
        let request = Acme_Telehealth_V1_SimulateVisitNoteRequest.with {
            $0.visitNoteID = rec.status
            $0.reason = rec.refillID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.simulateVisitNote(request)
        }
    }
}

/// Writes records to acme.compliance.v1.ComplianceCaseService.
struct CopyRefillWorkflowStatusComplianceCase: CopyRefillWorkflowStatusDestination {
    let client: Acme_Compliance_V1_ComplianceCaseService.Client<MeshTransport>

    func deliver(_ rec: CopyRefillWorkflowStatusRecord) async throws {
        _ = try await client.createComplianceCase(.with {
            $0.complianceCase.subject = rec.status
            $0.complianceCase.complianceCaseID = rec.resultStatus
            $0.requestID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CopyRefillWorkflowStatusLogOnly: CopyRefillWorkflowStatusDestination {
    let logger = Logger(label: "acme.copy-refill-workflow-status")

    func deliver(_ rec: CopyRefillWorkflowStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.prescriptions.v1.RefillWorkflowService/SignalRefillWorkflow and hands what it keeps to the sink of its kind.
enum CopyRefillWorkflowStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Prescriptions_V1_RefillWorkflowService.Client(wrapping: mesh)
        let found = try await upstream.signalRefillWorkflow(.with { $0.refillID = "current-copy-refill-workflow-status" })
        let entry = CopyRefillWorkflowStatusRecord(
            status: Kit.Text.normalize(found.outcome.status),
            refillID: found.refill.refillID,
            message: found.outcome.message,
            resultStatus: found.result.status
        )
        try await dispatch("visit-note-calculation", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: CopyRefillWorkflowStatusRecord, _ mesh: MeshClient) async throws {
        var write: (CopyRefillWorkflowStatusRecord) async throws -> Void = CopyRefillWorkflowStatusLogOnly().deliver
        switch kind {
        case "incident-query":
            write = CopyRefillWorkflowStatusIncidentQuery(client: Acme_Itsm_V1_IncidentQueryService.Client(wrapping: mesh)).deliver
        case "visit-note-calculation":
            write = CopyRefillWorkflowStatusVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)).deliver
        case "compliance-case":
            write = CopyRefillWorkflowStatusComplianceCase(client: Acme_Compliance_V1_ComplianceCaseService.Client(wrapping: mesh)).deliver
        default:
            break
        }
        try await write(rec)
    }
}
