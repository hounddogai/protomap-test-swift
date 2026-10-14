import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillTriageApprovalStatusSubject keeps of each GetTriageApprovalStatus response.
struct BackfillTriageApprovalStatusSubjectRecord {
    var subject: String
    var message: String
}

/// Where BackfillTriageApprovalStatusSubject hands each record.
protocol BackfillTriageApprovalStatusSubjectWriter {
    func send(_ rec: BackfillTriageApprovalStatusSubjectRecord) async throws
}

/// Sends records to acme.ledger.v1.LedgerAccountValidationService.
struct BackfillTriageApprovalStatusSubjectLedgerAccountValidation: BackfillTriageApprovalStatusSubjectWriter {
    let client: Acme_Ledger_V1_LedgerAccountValidationService.Client<MeshTransport>

    func send(_ rec: BackfillTriageApprovalStatusSubjectRecord) async throws {
        let request = Acme_Ledger_V1_ScoreLedgerAccountRequest.with {
            $0.ledgerAccount.ledgerAccountID = rec.subject
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.scoreLedgerAccount(request)
        }
    }
}

/// Sends records to acme.patients.v1.PatientLifecycleService.
struct BackfillTriageApprovalStatusSubjectPatientLifecycle: BackfillTriageApprovalStatusSubjectWriter {
    let client: Acme_Patients_V1_PatientLifecycleService.Client<MeshTransport>

    func send(_ rec: BackfillTriageApprovalStatusSubjectRecord) async throws {
        let request = Acme_Patients_V1_TerminatePatientRequest.with {
            $0.details.reasonCode = rec.subject
            $0.reason = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.terminatePatient(request)
        }
    }
}

/// Reads acme.telehealth.v1.TriageApprovalService/GetTriageApprovalStatus and hands what it keeps to the sink of its kind.
enum BackfillTriageApprovalStatusSubject {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_TriageApprovalService.Client(wrapping: mesh)
        let reply = try await upstream.getTriageApprovalStatus(.with { $0.triageID = "main-backfill-triage-approval-status-subject" })
        let entry = BackfillTriageApprovalStatusSubjectRecord(
            subject: reply.triage.subject,
            message: reply.result.message
        )
        let sinks: [String: any BackfillTriageApprovalStatusSubjectWriter] = [
            "ledger-account-validation": BackfillTriageApprovalStatusSubjectLedgerAccountValidation(client: Acme_Ledger_V1_LedgerAccountValidationService.Client(wrapping: mesh)),
            "patient-lifecycle": BackfillTriageApprovalStatusSubjectPatientLifecycle(client: Acme_Patients_V1_PatientLifecycleService.Client(wrapping: mesh)),
        ]
        try await route("ledger-account-validation", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: BackfillTriageApprovalStatusSubjectRecord, _ sinks: [String: any BackfillTriageApprovalStatusSubjectWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
