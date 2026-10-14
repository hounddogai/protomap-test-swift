import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncProviderApprovalStatusID keeps of each GetProviderApprovalStatus response.
struct SyncProviderApprovalStatusIDRecord {
    var correlationID: String
    var providerID: String
}

/// Where SyncProviderApprovalStatusID hands each record.
protocol SyncProviderApprovalStatusIDDestination {
    func apply(_ rec: SyncProviderApprovalStatusIDRecord) async throws
}

/// Sends records to acme.shipping.v1.ShipmentService.
struct SyncProviderApprovalStatusIDShipment: SyncProviderApprovalStatusIDDestination {
    let client: Acme_Shipping_V1_ShipmentService.Client<MeshTransport>

    func apply(_ rec: SyncProviderApprovalStatusIDRecord) async throws {
        _ = try await client.createShipment(.with {
            $0.shipment.number = rec.correlationID
        })
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct SyncProviderApprovalStatusIDBoxOfficeSaleCalculation: SyncProviderApprovalStatusIDDestination {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func apply(_ rec: SyncProviderApprovalStatusIDRecord) async throws {
        _ = try await client.estimateBoxOfficeSale(.with {
            $0.details.currencyCode = rec.correlationID
        })
    }
}

/// Reads acme.appointments.v1.ProviderApprovalService/GetProviderApprovalStatus and hands what it keeps to the sink of its kind.
enum SyncProviderApprovalStatusID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Appointments_V1_ProviderApprovalService.Client(wrapping: mesh)
        let got = try await origin.getProviderApprovalStatus(.with { $0.providerID = "main-sync-provider-approval-status-id" })
        let rec = SyncProviderApprovalStatusIDRecord(
            correlationID: got.result.correlationID,
            providerID: got.provider.providerID
        )
        let sinks: [any SyncProviderApprovalStatusIDDestination] = [
            SyncProviderApprovalStatusIDShipment(client: Acme_Shipping_V1_ShipmentService.Client(wrapping: mesh)),
            SyncProviderApprovalStatusIDBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].apply(rec)
    }
}
