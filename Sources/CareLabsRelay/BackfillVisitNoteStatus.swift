import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillVisitNoteStatus keeps of each PreviewVisitNote response.
struct BackfillVisitNoteStatusRecord {
    var status: String
    var notes: String
    var correlationID: String
}

/// Where BackfillVisitNoteStatus hands each record.
protocol BackfillVisitNoteStatusWriter {
    func forward(_ rec: BackfillVisitNoteStatusRecord) async throws
}

/// Sends records to acme.admissions.v1.AdmissionQueryService.
struct BackfillVisitNoteStatusAdmissionQuery: BackfillVisitNoteStatusWriter {
    let client: Acme_Admissions_V1_AdmissionQueryService.Client<MeshTransport>

    func forward(_ rec: BackfillVisitNoteStatusRecord) async throws {
        _ = try await client.lookupAdmission(.with {
            $0.admissionID = rec.correlationID
        })
    }
}

/// Passes records to acme.prescriptions.v1.MedicationReportingService.
struct BackfillVisitNoteStatusMedicationReporting: BackfillVisitNoteStatusWriter {
    let client: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>

    func forward(_ rec: BackfillVisitNoteStatusRecord) async throws {
        _ = try await client.shareMedicationReport(.with {
            $0.details.templateID = rec.notes
            $0.medicationID = rec.correlationID
            $0.details.channel = rec.status
        })
    }
}

/// Reads acme.telehealth.v1.VisitNoteValidationService/PreviewVisitNote and hands what it keeps to the sink of its kind.
enum BackfillVisitNoteStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)
        let got = try await upstream.previewVisitNote(.with { $0.visitNoteID = "live-backfill-visit-note-status" })
        let row = BackfillVisitNoteStatusRecord(
            status: got.result.status,
            notes: got.visitNote.notes,
            correlationID: got.result.correlationID
        )
        let sinks: [String: any BackfillVisitNoteStatusWriter] = [
            "admission-query": BackfillVisitNoteStatusAdmissionQuery(client: Acme_Admissions_V1_AdmissionQueryService.Client(wrapping: mesh)),
            "medication-reporting": BackfillVisitNoteStatusMedicationReporting(client: Acme_Prescriptions_V1_MedicationReportingService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "admission-query" {
                continue
            }
            try await sink.forward(row)
        }
    }
}
