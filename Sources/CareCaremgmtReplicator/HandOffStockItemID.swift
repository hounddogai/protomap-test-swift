import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What HandOffStockItemID keeps of each UpdateStockItem response.
struct HandOffStockItemIDRecord {
    var correlationID: String
    var message: String
}

/// Where HandOffStockItemID hands each record.
protocol HandOffStockItemIDTarget {
    func apply(_ rec: HandOffStockItemIDRecord) async throws
}

/// Hands records to acme.telehealth.v1.VisitNoteQueryService.
struct HandOffStockItemIDVisitNoteQuery: HandOffStockItemIDTarget {
    let client: Acme_Telehealth_V1_VisitNoteQueryService.Client<MeshTransport>

    func apply(_ rec: HandOffStockItemIDRecord) async throws {
        _ = try await client.summarizeVisitNotes(.with {
            $0.reason = rec.correlationID
        })
    }
}

/// Writes records to acme.appointments.v1.ProviderApprovalService.
struct HandOffStockItemIDProviderApproval: HandOffStockItemIDTarget {
    let client: Acme_Appointments_V1_ProviderApprovalService.Client<MeshTransport>

    func apply(_ rec: HandOffStockItemIDRecord) async throws {
        _ = try await client.escalateProvider(.with {
            $0.reason = rec.message
        })
    }
}

/// Hands records to acme.appointments.v1.AppointmentApprovalService.
struct HandOffStockItemIDAppointmentApproval: HandOffStockItemIDTarget {
    let client: Acme_Appointments_V1_AppointmentApprovalService.Client<MeshTransport>

    func apply(_ rec: HandOffStockItemIDRecord) async throws {
        _ = try await client.commentAppointmentApproval(.with {
            $0.appointment.appointmentID = rec.correlationID
            $0.details.approverEmail = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct HandOffStockItemIDLogOnly: HandOffStockItemIDTarget {
    let logger = Logger(label: "acme.hand-off-stock-item-id")

    func apply(_ rec: HandOffStockItemIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.inventory.v1.StockItemService/UpdateStockItem and hands what it keeps to the sink of its kind.
enum HandOffStockItemID {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)
        let response = try await upstream.updateStockItem(.init())
        let entry = HandOffStockItemIDRecord(
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        try await deliver("appointment-approval", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: HandOffStockItemIDRecord, _ mesh: MeshClient) async throws {
        var sink: any HandOffStockItemIDTarget = HandOffStockItemIDLogOnly()
        switch kind {
        case "visit-note-query":
            sink = HandOffStockItemIDVisitNoteQuery(client: Acme_Telehealth_V1_VisitNoteQueryService.Client(wrapping: mesh))
        case "provider-approval":
            sink = HandOffStockItemIDProviderApproval(client: Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh))
        case "appointment-approval":
            sink = HandOffStockItemIDAppointmentApproval(client: Acme_Appointments_V1_AppointmentApprovalService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.apply(rec)
    }
}
