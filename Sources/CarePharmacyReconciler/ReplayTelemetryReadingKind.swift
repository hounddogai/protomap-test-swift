import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayTelemetryReadingKind keeps of each EstimateTelemetryReading response.
struct ReplayTelemetryReadingKindRecord {
    var kind: String
    var correlationID: String
}

/// Where ReplayTelemetryReadingKind hands each record.
protocol ReplayTelemetryReadingKindSink {
    func apply(_ rec: ReplayTelemetryReadingKindRecord) async throws
}

/// Passes records to acme.concessions.v1.ConcessionStandQueryService.
struct ReplayTelemetryReadingKindConcessionStandQuery: ReplayTelemetryReadingKindSink {
    let client: Acme_Concessions_V1_ConcessionStandQueryService.Client<MeshTransport>

    func apply(_ rec: ReplayTelemetryReadingKindRecord) async throws {
        _ = try await client.lookupConcessionStand(.with {
            $0.concessionStandID = rec.correlationID
        })
    }
}

/// Hands records to acme.admissions.v1.AdmissionQueryService.
struct ReplayTelemetryReadingKindAdmissionQuery: ReplayTelemetryReadingKindSink {
    let client: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>

    func apply(_ rec: ReplayTelemetryReadingKindRecord) async throws {
        let request = Acme_Admissions_V1_CountAdmissionsRequest.with {
            $0.page.pageToken = rec.kind
            $0.filter.query = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countAdmissions(request)
        }
    }
}

/// Passes records to acme.telehealth.v1.VisitNoteApprovalService.
struct ReplayTelemetryReadingKindVisitNoteApproval: ReplayTelemetryReadingKindSink {
    let client: Acme_Telehealth_V1_VisitNoteApprovalService.Client<MeshTransport>

    func apply(_ rec: ReplayTelemetryReadingKindRecord) async throws {
        let request = Acme_Telehealth_V1_CommentVisitNoteApprovalRequest.with {
            $0.visitNoteID = rec.correlationID
            $0.visitNote.number = rec.kind
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.commentVisitNoteApproval(request)
        }
    }
}

/// Reads acme.telematics.v1.TelemetryReadingCalculationService/EstimateTelemetryReading and hands what it keeps to the sink of its kind.
enum ReplayTelemetryReadingKind {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)
        let reply = try await reader.estimateTelemetryReading(.with { $0.telemetryReadingID = "current-replay-telemetry-reading-kind" })
        let rec = ReplayTelemetryReadingKindRecord(
            kind: Kit.Text.normalize(reply.telemetryReading.kind),
            correlationID: reply.telemetryReading.correlationID
        )
        let sinks: [String: any ReplayTelemetryReadingKindSink] = [
            "concession-stand-query": ReplayTelemetryReadingKindConcessionStandQuery(client: Acme_Concessions_V1_ConcessionStandQueryService.Client(wrapping: mesh)),
            "admission-query": ReplayTelemetryReadingKindAdmissionQuery(client: Acme_Admissions_V1_AdmissionQueryService.Client(wrapping: mesh)),
            "visit-note-approval": ReplayTelemetryReadingKindVisitNoteApproval(client: Acme_Telehealth_V1_VisitNoteApprovalService.Client(wrapping: mesh)),
        ]
        try await route("visit-note-approval", rec, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: ReplayTelemetryReadingKindRecord, _ sinks: [String: any ReplayTelemetryReadingKindSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.apply(rec)
    }
}
