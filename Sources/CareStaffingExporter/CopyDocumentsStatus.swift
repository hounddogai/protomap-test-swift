import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What CopyDocumentsStatus keeps of each SummarizeDocuments response.
struct CopyDocumentsStatusRecord {
    var status: String
    var downloadUri: String
    var timezone: String
}

/// Where CopyDocumentsStatus hands each record.
protocol CopyDocumentsStatusDestination {
    func write(_ rec: CopyDocumentsStatusRecord) async throws
}

/// Sends records to acme.appointments.v1.ClinicSlotCalculationService.
struct CopyDocumentsStatusClinicSlotCalculation: CopyDocumentsStatusDestination {
    let client: Acme_Appointments_V1_ClinicSlotCalculationService.Client<MeshTransport>

    func write(_ rec: CopyDocumentsStatusRecord) async throws {
        let request = Acme_Appointments_V1_EstimateClinicSlotRequest.with {
            $0.reason = rec.downloadUri
            $0.clinicSlotID = rec.timezone
            $0.details.currencyCode = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.estimateClinicSlot(request)
        }
    }
}

/// Sends records to acme.yards.v1.YardCalculationService.
struct CopyDocumentsStatusYardCalculation: CopyDocumentsStatusDestination {
    let client: Acme_Yards_V1_YardCalculationService.Client<MeshTransport>

    func write(_ rec: CopyDocumentsStatusRecord) async throws {
        _ = try await client.recalculateYards(.with {
            $0.yardID = rec.status
        })
    }
}

/// Passes records to acme.inventory.v1.StockItemService.
struct CopyDocumentsStatusStockItem: CopyDocumentsStatusDestination {
    let client: Acme_Inventory_V1_StockItemService.Client<MeshTransport>

    func write(_ rec: CopyDocumentsStatusRecord) async throws {
        let request = Acme_Inventory_V1_SearchStockItemsRequest.with {
            $0.filter.ownerID = rec.downloadUri
            $0.page.pageToken = rec.status
            $0.orderBy = rec.timezone
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.searchStockItems(request)
        }
    }
}

/// Reads acme.documents.v1.DocumentQueryService/SummarizeDocuments and hands what it keeps to the sink of its kind.
enum CopyDocumentsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let upstream = Acme_Documents_V1_DocumentQueryService.Client(wrapping: mesh)
        let got = try await upstream.summarizeDocuments(.with { $0.documentID = "main-copy-documents-status" })
        let entry = CopyDocumentsStatusRecord(
            status: got.result.status,
            downloadUri: got.downloadUri,
            timezone: got.period.timezone
        )
        let sinks: [any CopyDocumentsStatusDestination] = [
            CopyDocumentsStatusClinicSlotCalculation(client: Acme_Appointments_V1_ClinicSlotCalculationService.Client(wrapping: mesh)),
            CopyDocumentsStatusYardCalculation(client: Acme_Yards_V1_YardCalculationService.Client(wrapping: mesh)),
            CopyDocumentsStatusStockItem(client: Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)),
        ]
        try await sinks[1].write(entry)
    }
}
