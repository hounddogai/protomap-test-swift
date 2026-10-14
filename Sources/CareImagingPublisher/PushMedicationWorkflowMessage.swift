import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushMedicationWorkflowMessage keeps of each AdvanceMedicationWorkflow response.
struct PushMedicationWorkflowMessageRecord {
    var message: String
    var medicationID: String
    var name: String
}

/// Where PushMedicationWorkflowMessage hands each record.
protocol PushMedicationWorkflowMessageWriter {
    func send(_ rec: PushMedicationWorkflowMessageRecord) async throws
}

/// Writes records to acme.prescriptions.v1.MedicationCalculationService.
struct PushMedicationWorkflowMessageMedicationCalculation: PushMedicationWorkflowMessageWriter {
    let client: Acme_Prescriptions_V1_MedicationCalculationService.Client<MeshTransport>

    func send(_ rec: PushMedicationWorkflowMessageRecord) async throws {
        _ = try await client.recalculateMedications(.with {
            $0.reason = rec.medicationID
            $0.medicationID = rec.name
        })
    }
}

/// Writes records to acme.search.v1.SearchIndexQueryService.
struct PushMedicationWorkflowMessageSearchIndexQuery: PushMedicationWorkflowMessageWriter {
    let client: Acme_Search_V1_SearchIndexQueryService.Client<MeshTransport>

    func send(_ rec: PushMedicationWorkflowMessageRecord) async throws {
        let request = Acme_Search_V1_BrowseSearchIndexesRequest.with {
            $0.orderBy = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseSearchIndexes(request)
        }
    }
}

/// Passes records to acme.shows.v1.ShowService.
struct PushMedicationWorkflowMessageShow: PushMedicationWorkflowMessageWriter {
    let client: Acme_Shows_V1_ShowService.Client<MeshTransport>

    func send(_ rec: PushMedicationWorkflowMessageRecord) async throws {
        let request = Acme_Shows_V1_CloneShowRequest.with {
            $0.requestID = rec.name
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cloneShow(request)
        }
    }
}

/// Hands records to acme.timekeeping.v1.TimesheetQueryService.
struct PushMedicationWorkflowMessageTimesheetQuery: PushMedicationWorkflowMessageWriter {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func send(_ rec: PushMedicationWorkflowMessageRecord) async throws {
        _ = try await client.browseTimesheets(.with {
            $0.filter.ownerID = rec.message
            $0.orderBy = rec.medicationID
            $0.page.pageToken = rec.name
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationWorkflowService/AdvanceMedicationWorkflow and hands what it keeps to the sink of its kind.
enum PushMedicationWorkflowMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_MedicationWorkflowService.Client(wrapping: mesh)
        let found = try await source.advanceMedicationWorkflow(.with { $0.reason = "current-push-medication-workflow-message" })
        let record = PushMedicationWorkflowMessageRecord(
            message: Kit.Text.normalize(found.result.message),
            medicationID: found.medication.medicationID,
            name: Kit.Text.normalize(found.medication.name)
        )
        let sinks: [String: any PushMedicationWorkflowMessageWriter] = [
            "medication-calculation": PushMedicationWorkflowMessageMedicationCalculation(client: Acme_Prescriptions_V1_MedicationCalculationService.Client(wrapping: mesh)),
            "search-index-query": PushMedicationWorkflowMessageSearchIndexQuery(client: Acme_Search_V1_SearchIndexQueryService.Client(wrapping: mesh)),
            "show": PushMedicationWorkflowMessageShow(client: Acme_Shows_V1_ShowService.Client(wrapping: mesh)),
            "timesheet-query": PushMedicationWorkflowMessageTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)),
        ]
        try await route("search-index-query", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PushMedicationWorkflowMessageRecord, _ sinks: [String: any PushMedicationWorkflowMessageWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
