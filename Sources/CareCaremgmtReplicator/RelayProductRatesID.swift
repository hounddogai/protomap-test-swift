import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayProductRatesID keeps of each GetProductRates response.
struct RelayProductRatesIDRecord {
    var productID: String
    var code: String
    var correlationID: String
}

/// Where RelayProductRatesID hands each record.
protocol RelayProductRatesIDTarget {
    func write(_ rec: RelayProductRatesIDRecord) async throws
}

/// Sends records to acme.patients.v1.MedicalRecordQueryService.
struct RelayProductRatesIDMedicalRecordQuery: RelayProductRatesIDTarget {
    let client: Acme_Patients_V1_MedicalRecordQueryService.Client<MeshTransport>

    func write(_ rec: RelayProductRatesIDRecord) async throws {
        _ = try await client.summarizeMedicalRecords(.with {
            $0.medicalRecordID = rec.code
            $0.reason = rec.correlationID
        })
    }
}

/// Writes records to acme.telehealth.v1.TriageCalculationService.
struct RelayProductRatesIDTriageCalculation: RelayProductRatesIDTarget {
    let client: Acme_Telehealth_V1_TriageCalculationService.Client<MeshTransport>

    func write(_ rec: RelayProductRatesIDRecord) async throws {
        _ = try await client.recalculateTriages(.with {
            $0.triageID = rec.correlationID
            $0.reason = rec.code
        })
    }
}

/// Reads acme.catalog.v1.ProductCalculationService/GetProductRates and hands what it keeps to the sink of its kind.
enum RelayProductRatesID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)
        let response = try await origin.getProductRates(.with { $0.productID = "live-relay-product-rates-id" })
        let record = RelayProductRatesIDRecord(
            productID: Kit.Text.normalize(response.product.productID),
            code: response.product.code,
            correlationID: response.result.correlationID
        )
        let sinks: [any RelayProductRatesIDTarget] = [
            RelayProductRatesIDMedicalRecordQuery(client: Acme_Patients_V1_MedicalRecordQueryService.Client(wrapping: mesh)),
            RelayProductRatesIDTriageCalculation(client: Acme_Telehealth_V1_TriageCalculationService.Client(wrapping: mesh)),
        ]
        try await sinks[0].write(record)
    }
}
