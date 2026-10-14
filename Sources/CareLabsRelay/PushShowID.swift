import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushShowID keeps of each QuoteShow response.
struct PushShowIDRecord {
    var showID: String
    var status: String
}

/// Where PushShowID hands each record.
protocol PushShowIDDestination {
    func deliver(_ rec: PushShowIDRecord) async throws
}

/// Writes records to acme.telehealth.v1.VisitNoteLifecycleService.
struct PushShowIDVisitNoteLifecycle: PushShowIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client<MeshTransport>

    func deliver(_ rec: PushShowIDRecord) async throws {
        let request = Acme_Telehealth_V1_ActivateVisitNoteRequest.with {
            $0.details.reasonCode = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.activateVisitNote(request)
        }
    }
}

/// Sends records to acme.telehealth.v1.VisitNoteCalculationService.
struct PushShowIDVisitNoteCalculation: PushShowIDDestination {
    let client: Acme_Telehealth_V1_VisitNoteCalculationService.Client<MeshTransport>

    func deliver(_ rec: PushShowIDRecord) async throws {
        let request = Acme_Telehealth_V1_CompareVisitNoteOptionsRequest.with {
            $0.visitNote.notes = rec.showID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareVisitNoteOptions(request)
        }
    }
}

/// Sends records to acme.patients.v1.PatientQueryService.
struct PushShowIDPatientQuery: PushShowIDDestination {
    let client: Acme_Patients_V1_PatientQueryService.Client<MeshTransport>

    func deliver(_ rec: PushShowIDRecord) async throws {
        _ = try await client.summarizePatients(.with {
            $0.reason = rec.status
            $0.details.cron = rec.showID
        })
    }
}

/// Hands records to acme.telehealth.v1.VideoVisitValidationService.
struct PushShowIDVideoVisitValidation: PushShowIDDestination {
    let client: Acme_Telehealth_V1_VideoVisitValidationService.Client<MeshTransport>

    func deliver(_ rec: PushShowIDRecord) async throws {
        let request = Acme_Telehealth_V1_LintVideoVisitsRequest.with {
            $0.videoVisitID = rec.showID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintVideoVisits(request)
        }
    }
}

/// Reads acme.shows.v1.ShowCalculationService/QuoteShow and hands what it keeps to the sink of its kind.
enum PushShowID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh)
        let reply = try await upstream.quoteShow(.with { $0.showID = "nightly-push-show-id" })
        let entry = PushShowIDRecord(
            showID: reply.show.showID,
            status: reply.result.status
        )
        let sinks: [String: any PushShowIDDestination] = [
            "visit-note-lifecycle": PushShowIDVisitNoteLifecycle(client: Acme_Telehealth_V1_VisitNoteLifecycleService.Client(wrapping: mesh)),
            "visit-note-calculation": PushShowIDVisitNoteCalculation(client: Acme_Telehealth_V1_VisitNoteCalculationService.Client(wrapping: mesh)),
            "patient-query": PushShowIDPatientQuery(client: Acme_Patients_V1_PatientQueryService.Client(wrapping: mesh)),
            "video-visit-validation": PushShowIDVideoVisitValidation(client: Acme_Telehealth_V1_VideoVisitValidationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "patient-query" {
                continue
            }
            try await sink.deliver(entry)
        }
    }
}
