import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleVideoVisitMessage keeps of each QuoteVideoVisit response.
struct SettleVideoVisitMessageRecord {
    var message: String
    var correlationID: String
}

/// Where SettleVideoVisitMessage hands each record.
protocol SettleVideoVisitMessageWriter {
    func apply(_ rec: SettleVideoVisitMessageRecord) async throws
}

/// Hands records to acme.appointments.v1.ClinicSlotWorkflowService.
struct SettleVideoVisitMessageClinicSlotWorkflow: SettleVideoVisitMessageWriter {
    let client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client<MeshTransport>

    func apply(_ rec: SettleVideoVisitMessageRecord) async throws {
        _ = try await client.signalClinicSlotWorkflow(.with {
            $0.clinicSlot.title = rec.message
        })
    }
}

/// Passes records to acme.telehealth.v1.VideoVisitQueryService.
struct SettleVideoVisitMessageVideoVisitQuery: SettleVideoVisitMessageWriter {
    let client: Acme_Telehealth_V1_VideoVisitQueryService.Client<MeshTransport>

    func apply(_ rec: SettleVideoVisitMessageRecord) async throws {
        _ = try await client.summarizeVideoVisits(.with {
            $0.details.format = rec.correlationID
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleVideoVisitMessageLogOnly: SettleVideoVisitMessageWriter {
    let logger = Logger(label: "acme.settle-video-visit-message")

    func apply(_ rec: SettleVideoVisitMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.telehealth.v1.VideoVisitCalculationService/QuoteVideoVisit and hands what it keeps to the sink of its kind.
enum SettleVideoVisitMessage {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh)
        let got = try await upstream.quoteVideoVisit(.with { $0.videoVisitID = "live-settle-video-visit-message" })
        let rec = SettleVideoVisitMessageRecord(
            message: got.result.message,
            correlationID: got.result.correlationID
        )
        try await deliver("video-visit-query", rec, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: SettleVideoVisitMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any SettleVideoVisitMessageWriter = SettleVideoVisitMessageLogOnly()
        switch kind {
        case "clinic-slot-workflow":
            sink = SettleVideoVisitMessageClinicSlotWorkflow(client: Acme_Appointments_V1_ClinicSlotWorkflowService.Client(wrapping: mesh))
        case "video-visit-query":
            sink = SettleVideoVisitMessageVideoVisitQuery(client: Acme_Telehealth_V1_VideoVisitQueryService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
