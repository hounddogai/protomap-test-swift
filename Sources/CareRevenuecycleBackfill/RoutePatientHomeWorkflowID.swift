import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RoutePatientHomeWorkflowID keeps of each InspectPatientHomeWorkflow response.
struct RoutePatientHomeWorkflowIDRecord {
    var correlationID: String
    var subject: String
    var status: String
}

/// Where RoutePatientHomeWorkflowID hands each record.
protocol RoutePatientHomeWorkflowIDDestination {
    func write(_ rec: RoutePatientHomeWorkflowIDRecord) async throws
}

/// Sends records to acme.accounting.v1.ChartOfAccountsService.
struct RoutePatientHomeWorkflowIDChartOfAccounts: RoutePatientHomeWorkflowIDDestination {
    let client: Acme_Accounting_V1_ChartOfAccountsService.Client<MeshTransport>

    func write(_ rec: RoutePatientHomeWorkflowIDRecord) async throws {
        let request = Acme_Accounting_V1_GetChartOfAccountsRequest.with {
            $0.chartOfAccountsID = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.getChartOfAccounts(request)
        }
    }
}

/// Writes records to acme.prescriptions.v1.MedicationApprovalService.
struct RoutePatientHomeWorkflowIDMedicationApproval: RoutePatientHomeWorkflowIDDestination {
    let client: Acme_Prescriptions_V1_MedicationApprovalService.Client<MeshTransport>

    func write(_ rec: RoutePatientHomeWorkflowIDRecord) async throws {
        _ = try await client.recallMedication(.with {
            $0.medication.name = rec.status
            $0.medication.medicationID = rec.subject
        })
    }
}

/// Writes records to acme.audiences.v1.AudienceService.
struct RoutePatientHomeWorkflowIDAudience: RoutePatientHomeWorkflowIDDestination {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func write(_ rec: RoutePatientHomeWorkflowIDRecord) async throws {
        let request = Acme_Audiences_V1_SearchAudiencesRequest.with {
            $0.filter.ownerID = rec.correlationID
            $0.orderBy = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchAudiences(request)
        }
    }
}

/// Hands records to acme.telehealth.v1.VisitNoteQueryService.
struct RoutePatientHomeWorkflowIDVisitNoteQuery: RoutePatientHomeWorkflowIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>

    func write(_ rec: RoutePatientHomeWorkflowIDRecord) async throws {
        _ = try await client.countVisitNotes(.with {
            $0.filter.region = rec.correlationID
            $0.filter.ownerID = rec.subject
            $0.page.pageToken = rec.status
        })
    }
}

/// Reads acme.patientapp.v1.PatientHomeWorkflowService/InspectPatientHomeWorkflow and hands what it keeps to the sink of its kind.
enum RoutePatientHomeWorkflowID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)
        let found = try await source.inspectPatientHomeWorkflow(.with { $0.patientHomeID = "current-route-patient-home-workflow-id" })
        let record = RoutePatientHomeWorkflowIDRecord(
            correlationID: Kit.Text.normalize(found.result.correlationID),
            subject: found.patientHome.subject,
            status: found.result.status
        )
        let sinks: [String: any RoutePatientHomeWorkflowIDDestination] = [
            "chart-of-accounts": RoutePatientHomeWorkflowIDChartOfAccounts(client: Acme_Accounting_V1_ChartOfAccountsService.Client(wrapping: mesh)),
            "medication-approval": RoutePatientHomeWorkflowIDMedicationApproval(client: Acme_Prescriptions_V1_MedicationApprovalService.Client(wrapping: mesh)),
            "audience": RoutePatientHomeWorkflowIDAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)),
            "visit-note-query": RoutePatientHomeWorkflowIDVisitNoteQuery(client: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: mesh)),
        ]
        try await route("medication-approval", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RoutePatientHomeWorkflowIDRecord, _ sinks: [String: any RoutePatientHomeWorkflowIDDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
