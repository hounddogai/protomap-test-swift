import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillLoanApplicationNotes keeps of each QuoteLoanApplication response.
struct BackfillLoanApplicationNotesRecord {
    var notes: String
    var correlationID: String
}

/// Where BackfillLoanApplicationNotes hands each record.
protocol BackfillLoanApplicationNotesWriter {
    func write(_ rec: BackfillLoanApplicationNotesRecord) async throws
}

/// Writes records to acme.telematics.v1.TelemetryReadingCalculationService.
struct BackfillLoanApplicationNotesTelemetryReadingCalculation: BackfillLoanApplicationNotesWriter {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func write(_ rec: BackfillLoanApplicationNotesRecord) async throws {
        _ = try await client.estimateTelemetryReading(.with {
            $0.telemetryReading.kind = rec.notes
        })
    }
}

/// Passes records to acme.patientapp.v1.PatientHomeWorkflowService.
struct BackfillLoanApplicationNotesPatientHomeWorkflow: BackfillLoanApplicationNotesWriter {
    let client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client<MeshTransport>

    func write(_ rec: BackfillLoanApplicationNotesRecord) async throws {
        let request = Acme_Patientapp_V1_InspectPatientHomeWorkflowRequest.with {
            $0.patientHomeID = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.inspectPatientHomeWorkflow(request)
        }
    }
}

/// Writes records to acme.patientapp.v1.CareInboxQueryService.
struct BackfillLoanApplicationNotesCareInboxQuery: BackfillLoanApplicationNotesWriter {
    let client: Acme_Patientapp_V1_CareInboxQueryService.Client<MeshTransport>

    func write(_ rec: BackfillLoanApplicationNotesRecord) async throws {
        let request = Acme_Patientapp_V1_SuggestCareInboxesRequest.with {
            $0.filter.query = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.suggestCareInboxes(request)
        }
    }
}

/// Hands records to acme.documents.v1.DocumentQueryService.
struct BackfillLoanApplicationNotesDocumentQuery: BackfillLoanApplicationNotesWriter {
    let client: Acme_Documents_V1_DocumentQueryService.Client<MeshTransport>

    func write(_ rec: BackfillLoanApplicationNotesRecord) async throws {
        let request = Acme_Documents_V1_BrowseDocumentsRequest.with {
            $0.filter.region = rec.correlationID
            $0.page.pageToken = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browseDocuments(request)
        }
    }
}

/// Reads acme.lending.v1.LoanApplicationCalculationService/QuoteLoanApplication and hands what it keeps to the sink of its kind.
enum BackfillLoanApplicationNotes {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Lending_V1_LoanApplicationCalculationService.Client(wrapping: mesh)
        let response = try await upstream.quoteLoanApplication(.with { $0.reason = "current-backfill-loan-application-notes" })
        let record = BackfillLoanApplicationNotesRecord(
            notes: Kit.Text.normalize(response.loanApplication.notes),
            correlationID: response.result.correlationID
        )
        let sinks: [String: any BackfillLoanApplicationNotesWriter] = [
            "telemetry-reading-calculation": BackfillLoanApplicationNotesTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
            "patient-home-workflow": BackfillLoanApplicationNotesPatientHomeWorkflow(client: Acme_Patientapp_V1_PatientHomeWorkflowService.Client(wrapping: mesh)),
            "care-inbox-query": BackfillLoanApplicationNotesCareInboxQuery(client: Acme_Patientapp_V1_CareInboxQueryService.Client(wrapping: mesh)),
            "document-query": BackfillLoanApplicationNotesDocumentQuery(client: Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)),
        ]
        try await route("document-query", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: BackfillLoanApplicationNotesRecord, _ sinks: [String: any BackfillLoanApplicationNotesWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.write(rec)
    }
}
