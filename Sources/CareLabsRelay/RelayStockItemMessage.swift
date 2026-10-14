import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayStockItemMessage keeps of each CreateStockItem response.
struct RelayStockItemMessageRecord {
    var message: String
    var name: String
    var status: String
}

/// Where RelayStockItemMessage hands each record.
protocol RelayStockItemMessageTarget {
    func write(_ rec: RelayStockItemMessageRecord) async throws
}

/// Sends records to acme.telehealth.v1.VideoVisitCalculationService.
struct RelayStockItemMessageVideoVisitCalculation: RelayStockItemMessageTarget {
    let client: Acme_Telehealth_V1_VideoVisitCalculationService.Client<MeshTransport>

    func write(_ rec: RelayStockItemMessageRecord) async throws {
        _ = try await client.quoteVideoVisit(.with {
            $0.details.currencyCode = rec.message
            $0.videoVisit.videoVisitID = rec.status
            $0.videoVisitID = rec.name
        })
    }
}

/// Writes records to acme.patients.v1.AllergyCalculationService.
struct RelayStockItemMessageAllergyCalculation: RelayStockItemMessageTarget {
    let client: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>

    func write(_ rec: RelayStockItemMessageRecord) async throws {
        _ = try await client.getAllergyRates(.with {
            $0.allergyID = rec.message
        })
    }
}

/// Hands records to acme.careplans.v1.CarePlanCalculationService.
struct RelayStockItemMessageCarePlanCalculation: RelayStockItemMessageTarget {
    let client: Acme_Careplans_V1_CarePlanCalculationService.Client<MeshTransport>

    func write(_ rec: RelayStockItemMessageRecord) async throws {
        _ = try await client.simulateCarePlan(.with {
            $0.carePlanID = rec.name
            $0.carePlan.notes = rec.status
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct RelayStockItemMessageLogOnly: RelayStockItemMessageTarget {
    let logger = Logger(label: "acme.relay-stock-item-message")

    func write(_ rec: RelayStockItemMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.inventory.v1.StockItemService/CreateStockItem and hands what it keeps to the sink of its kind.
enum RelayStockItemMessage {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)
        let response = try await source.createStockItem(.with { $0.requestID = "main-relay-stock-item-message" })
        let entry = RelayStockItemMessageRecord(
            message: response.result.message,
            name: response.stockItem.name,
            status: Kit.Text.normalize(response.result.status)
        )
        try await deliver("care-plan-calculation", entry, mesh)
    }

    /// Hands a record to the sink of its kind.
    static func deliver(_ kind: String, _ rec: RelayStockItemMessageRecord, _ mesh: MeshClient) async throws {
        var sink: any RelayStockItemMessageTarget = RelayStockItemMessageLogOnly()
        switch kind {
        case "video-visit-calculation":
            sink = RelayStockItemMessageVideoVisitCalculation(client: Acme_Telehealth_V1_VideoVisitCalculationService.Client(wrapping: mesh))
        case "allergy-calculation":
            sink = RelayStockItemMessageAllergyCalculation(client: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh))
        case "care-plan-calculation":
            sink = RelayStockItemMessageCarePlanCalculation(client: Acme_Careplans_V1_CarePlanCalculationService.Client(wrapping: mesh))
        default:
            break
        }
        try await sink.write(rec)
    }
}
