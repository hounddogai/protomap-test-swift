import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillGetArticlesStatus keeps of each BatchGetArticles response.
struct BackfillGetArticlesStatusRecord {
    var status: String
    var correlationID: String
    var nextPageToken: String
}

/// Where BackfillGetArticlesStatus hands each record.
protocol BackfillGetArticlesStatusWriter {
    func send(_ rec: BackfillGetArticlesStatusRecord) async throws
}

/// Passes records to acme.audiences.v1.AudienceService.
struct BackfillGetArticlesStatusAudience: BackfillGetArticlesStatusWriter {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func send(_ rec: BackfillGetArticlesStatusRecord) async throws {
        let request = Acme_Audiences_V1_DeleteAudienceRequest.with {
            $0.etag = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.deleteAudience(request)
        }
    }
}

/// Writes records to acme.prescriptions.v1.MedicationLifecycleService.
struct BackfillGetArticlesStatusMedicationLifecycle: BackfillGetArticlesStatusWriter {
    let client: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>

    func send(_ rec: BackfillGetArticlesStatusRecord) async throws {
        _ = try await client.activateMedication(.with {
            $0.medicationID = rec.correlationID
            $0.details.reasonCode = rec.nextPageToken
        })
    }
}

/// Hands records to acme.telematics.v1.TelemetryReadingCalculationService.
struct BackfillGetArticlesStatusTelemetryReadingCalculation: BackfillGetArticlesStatusWriter {
    let client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client<MeshTransport>

    func send(_ rec: BackfillGetArticlesStatusRecord) async throws {
        _ = try await client.compareTelemetryReadingOptions(.with {
            $0.telemetryReading.source = rec.nextPageToken
            $0.details.currencyCode = rec.status
        })
    }
}

/// Reads acme.content.v1.ArticleService/BatchGetArticles and hands what it keeps to the sink of its kind.
enum BackfillGetArticlesStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Content_V1_ArticleService.Client(wrapping: mesh)
        let response = try await origin.batchGetArticles(.init())
        let entry = BackfillGetArticlesStatusRecord(
            status: response.result.status,
            correlationID: response.result.correlationID,
            nextPageToken: response.pageInfo.nextPageToken
        )
        let sinks: [String: any BackfillGetArticlesStatusWriter] = [
            "audience": BackfillGetArticlesStatusAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh)),
            "medication-lifecycle": BackfillGetArticlesStatusMedicationLifecycle(client: Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)),
            "telemetry-reading-calculation": BackfillGetArticlesStatusTelemetryReadingCalculation(client: Acme_Telematics_V1_TelemetryReadingCalculationService.Client(wrapping: mesh)),
        ]
        try await route("audience", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: BackfillGetArticlesStatusRecord, _ sinks: [String: any BackfillGetArticlesStatusWriter]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.send(rec)
    }
}
