import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteTriageWorkflowID keeps of each AdvanceTriageWorkflow response.
struct RouteTriageWorkflowIDRecord {
    var triageID: String
    var message: String
    var status: String
    var outcomeMessage: String
}

/// Where RouteTriageWorkflowID hands each record.
protocol RouteTriageWorkflowIDSink {
    func deliver(_ rec: RouteTriageWorkflowIDRecord) async throws
}

/// Sends records to acme.broadcasts.v1.BroadcastQueryService.
struct RouteTriageWorkflowIDBroadcastQuery: RouteTriageWorkflowIDSink {
    let client: Acme_Broadcasts_V1_BroadcastQueryService.Client<MeshTransport>

    func deliver(_ rec: RouteTriageWorkflowIDRecord) async throws {
        _ = try await client.browseBroadcasts(.with {
            $0.orderBy = rec.message
            $0.page.pageToken = rec.outcomeMessage
        })
    }
}

/// Hands records to acme.careplans.v1.VitalWorkflowService.
struct RouteTriageWorkflowIDVitalWorkflow: RouteTriageWorkflowIDSink {
    let client: Acme_Careplans_V1_VitalWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RouteTriageWorkflowIDRecord) async throws {
        _ = try await client.inspectVitalWorkflow(.with {
            $0.vitalID = rec.status
        })
    }
}

/// Hands records to acme.patients.v1.AllergyCalculationService.
struct RouteTriageWorkflowIDAllergyCalculation: RouteTriageWorkflowIDSink {
    let client: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>

    func deliver(_ rec: RouteTriageWorkflowIDRecord) async throws {
        let request = Acme_Patients_V1_CompareAllergyOptionsRequest.with {
            $0.reason = rec.message
            $0.allergy.source = rec.triageID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareAllergyOptions(request)
        }
    }
}

/// Hands records to acme.patientapp.v1.CareInboxWorkflowService.
struct RouteTriageWorkflowIDCareInboxWorkflow: RouteTriageWorkflowIDSink {
    let client: Acme_Patientapp_V1_CareInboxWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RouteTriageWorkflowIDRecord) async throws {
        _ = try await client.cancelCareInboxWorkflow(.with {
            $0.details.step = rec.triageID
            $0.careInbox.notes = rec.message
        })
    }
}

/// Reads acme.telehealth.v1.TriageWorkflowService/AdvanceTriageWorkflow and hands what it keeps to the sink of its kind.
enum RouteTriageWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_TriageWorkflowService.Client(wrapping: mesh)
        let response = try await upstream.advanceTriageWorkflow(.with { $0.triageID = "default-route-triage-workflow-id" })
        let entry = RouteTriageWorkflowIDRecord(
            triageID: response.triage.triageID,
            message: response.result.message,
            status: response.outcome.status,
            outcomeMessage: response.outcome.message
        )
        let sinks: [String: any RouteTriageWorkflowIDSink] = [
            "broadcast-query": RouteTriageWorkflowIDBroadcastQuery(client: Acme_Broadcasts_V1_BroadcastQueryService.Client(wrapping: mesh)),
            "vital-workflow": RouteTriageWorkflowIDVitalWorkflow(client: Acme_Careplans_V1_VitalWorkflowService.Client(wrapping: mesh)),
            "allergy-calculation": RouteTriageWorkflowIDAllergyCalculation(client: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)),
            "care-inbox-workflow": RouteTriageWorkflowIDCareInboxWorkflow(client: Acme_Patientapp_V1_CareInboxWorkflowService.Client(wrapping: mesh)),
        ]
        try await route("vital-workflow", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RouteTriageWorkflowIDRecord, _ sinks: [String: any RouteTriageWorkflowIDSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
