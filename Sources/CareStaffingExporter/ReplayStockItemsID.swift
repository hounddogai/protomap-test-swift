import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What ReplayStockItemsID keeps of each ListStockItems response.
struct ReplayStockItemsIDRecord {
    var correlationID: String
    var message: String
}

/// Where ReplayStockItemsID hands each record.
protocol ReplayStockItemsIDSink {
    func send(_ rec: ReplayStockItemsIDRecord) async throws
}

/// Passes records to acme.careplans.v1.VitalReportingService.
struct ReplayStockItemsIDVitalReporting: ReplayStockItemsIDSink {
    let client: Acme_Careplans_V1_VitalReportingService.Client<MeshTransport>

    func send(_ rec: ReplayStockItemsIDRecord) async throws {
        _ = try await client.countVitalTotals(.with {
            $0.page.pageToken = rec.message
        })
    }
}

/// Writes records to acme.fanportal.v1.FanSessionService.
struct ReplayStockItemsIDFanSession: ReplayStockItemsIDSink {
    let client: Acme_Fanportal_V1_FanSessionService.Client<MeshTransport>

    func send(_ rec: ReplayStockItemsIDRecord) async throws {
        _ = try await client.updateFanSession(.with {
            $0.fanSession.fanSessionID = rec.correlationID
            $0.fanSession.subject = rec.message
        })
    }
}

/// Writes records to acme.prescriptions.v1.PrescriptionApprovalService.
struct ReplayStockItemsIDPrescriptionApproval: ReplayStockItemsIDSink {
    let client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client<MeshTransport>

    func send(_ rec: ReplayStockItemsIDRecord) async throws {
        _ = try await client.escalatePrescription(.with {
            $0.prescription.notes = rec.message
        })
    }
}

/// Sends records to acme.shows.v1.ShowCalculationService.
struct ReplayStockItemsIDShowCalculation: ReplayStockItemsIDSink {
    let client: Acme_Shows_V1_ShowCalculationService.Client<MeshTransport>

    func send(_ rec: ReplayStockItemsIDRecord) async throws {
        let request = Acme_Shows_V1_QuoteShowRequest.with {
            $0.showID = rec.correlationID
            $0.show.title = rec.message
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.quoteShow(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct ReplayStockItemsIDLogOnly: ReplayStockItemsIDSink {
    let logger = Logger(label: "acme.replay-stock-items-id")

    func send(_ rec: ReplayStockItemsIDRecord) async throws {
        logger.info("No sink for record", metadata: ["correlationID": .string(rec.correlationID)])
    }
}

/// Reads acme.inventory.v1.StockItemService/ListStockItems and hands what it keeps to the sink of its kind.
enum ReplayStockItemsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)
        let response = try await reader.listStockItems(.with { $0.orderBy = "primary-replay-stock-items-id" })
        let record = ReplayStockItemsIDRecord(
            correlationID: response.result.correlationID,
            message: response.result.message
        )
        try await deliver("prescription-approval", record, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: ReplayStockItemsIDRecord, _ mesh: MeshClient) async throws {
        var sink: any ReplayStockItemsIDSink = ReplayStockItemsIDLogOnly()
        switch kind {
        case "vital-reporting":
            sink = ReplayStockItemsIDVitalReporting(client: Acme_Careplans_V1_VitalReportingService.Client(wrapping: mesh))
        case "fan-session":
            sink = ReplayStockItemsIDFanSession(client: Acme_Fanportal_V1_FanSessionService.Client(wrapping: mesh))
        case "prescription-approval":
            sink = ReplayStockItemsIDPrescriptionApproval(client: Acme_Prescriptions_V1_PrescriptionApprovalService.Client(wrapping: mesh))
        case "show-calculation":
            sink = ReplayStockItemsIDShowCalculation(client: Acme_Shows_V1_ShowCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.send(rec)
    }
}
