import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CarryCorporateEventMessage keeps of each PeekCorporateEvent response.
struct CarryCorporateEventMessageRecord {
    var message: String
    var title: String
    var correlationID: String
}

/// Where CarryCorporateEventMessage hands each record.
protocol CarryCorporateEventMessageWriter {
    func write(_ rec: CarryCorporateEventMessageRecord) async throws
}

/// Writes records to acme.prescriptions.v1.MedicationReportingService.
struct CarryCorporateEventMessageMedicationReporting: CarryCorporateEventMessageWriter {
    let client: Acme_Prescriptions_V1_MedicationReportingService.Client<MeshTransport>

    func write(_ rec: CarryCorporateEventMessageRecord) async throws {
        let request = Acme_Prescriptions_V1_GenerateMedicationReportRequest.with {
            $0.medicationID = rec.message
            $0.reason = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.generateMedicationReport(request)
        }
    }
}

/// Writes records to acme.audiences.v1.AudienceService.
struct CarryCorporateEventMessageAudience: CarryCorporateEventMessageWriter {
    let client: Acme_Audiences_V1_AudienceService.Client<MeshTransport>

    func write(_ rec: CarryCorporateEventMessageRecord) async throws {
        _ = try await client.deleteAudience(.with {
            $0.reason = rec.title
            $0.audienceID = rec.correlationID
            $0.etag = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct CarryCorporateEventMessageLogOnly: CarryCorporateEventMessageWriter {
    let logger = Logger(label: "acme.carry-corporate-event-message")

    func write(_ rec: CarryCorporateEventMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.corporateevents.v1.CorporateEventQueryService/PeekCorporateEvent and hands what it keeps to the sink of its kind.
enum CarryCorporateEventMessage {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Corporateevents_V1_CorporateEventQueryService.Client(wrapping: mesh)
        let got = try await origin.peekCorporateEvent(.with { $0.corporateEventID = "nightly-carry-corporate-event-message" })
        let entry = CarryCorporateEventMessageRecord(
            message: Kit.Text.normalize(got.result.message),
            title: Kit.Text.normalize(got.corporateEvent.title),
            correlationID: Kit.Text.normalize(got.result.correlationID)
        )
        try await deliver("medication-reporting", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: CarryCorporateEventMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any CarryCorporateEventMessageWriter = CarryCorporateEventMessageLogOnly()
        switch kind {
        case "medication-reporting":
            sink = CarryCorporateEventMessageMedicationReporting(client: Acme_Prescriptions_V1_MedicationReportingService.Client(wrapping: mesh))
        case "audience":
            sink = CarryCorporateEventMessageAudience(client: Acme_Audiences_V1_AudienceService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
