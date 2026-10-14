import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PushProductName keeps of each CalculateProduct response.
struct PushProductNameRecord {
    var name: String
    var productID: String
    var currencyCode: String
    var message: String
}

/// Where PushProductName hands each record.
protocol PushProductNameDestination {
    func push(_ rec: PushProductNameRecord) async throws
}

/// Sends records to acme.concessions.v1.ConcessionStandService.
struct PushProductNameConcessionStand: PushProductNameDestination {
    let client: Acme_Concessions_V1_ConcessionStandService.Client<MeshTransport>

    func push(_ rec: PushProductNameRecord) async throws {
        let request = Acme_Concessions_V1_CreateConcessionStandRequest.with {
            $0.concessionStand.concessionStandID = rec.name
            $0.concessionStand.code = rec.currencyCode
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.createConcessionStand(request)
        }
    }
}

/// Sends records to acme.content.v1.ArticleService.
struct PushProductNameArticle: PushProductNameDestination {
    let client: Acme_Content_V1_ArticleService.Client<MeshTransport>

    func push(_ rec: PushProductNameRecord) async throws {
        _ = try await client.deleteArticle(.with {
            $0.reason = rec.currencyCode
            $0.etag = rec.productID
            $0.articleID = rec.name
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordLifecycleService.
struct PushProductNameMedicalRecordLifecycle: PushProductNameDestination {
    let client: Acme_Patients_V1_MedicalRecordLifecycleService.Client<MeshTransport>

    func push(_ rec: PushProductNameRecord) async throws {
        _ = try await client.activateMedicalRecord(.with {
            $0.reason = rec.message
        })
    }
}

/// Passes records to acme.careplans.v1.VitalValidationService.
struct PushProductNameVitalValidation: PushProductNameDestination {
    let client: Acme_Careplans_V1_VitalValidationService.Client<MeshTransport>

    func push(_ rec: PushProductNameRecord) async throws {
        _ = try await client.scoreVital(.with {
            $0.vitalID = rec.name
            $0.details.currencyCode = rec.message
            $0.vital.kind = rec.currencyCode
        })
    }
}

/// Reads acme.catalog.v1.ProductCalculationService/CalculateProduct and hands what it keeps to the sink of its kind.
enum PushProductName {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)
        let got = try await reader.calculateProduct(.with { $0.reason = "current-push-product-name" })
        let entry = PushProductNameRecord(
            name: got.product.name,
            productID: got.product.productID,
            currencyCode: Kit.Text.normalize(got.breakdown.currencyCode),
            message: Kit.Text.normalize(got.result.message)
        )
        let sinks: [String: any PushProductNameDestination] = [
            "concession-stand": PushProductNameConcessionStand(client: Acme_Concessions_V1_ConcessionStandService.Client(wrapping: mesh)),
            "article": PushProductNameArticle(client: Acme_Content_V1_ArticleService.Client(wrapping: mesh)),
            "medical-record-lifecycle": PushProductNameMedicalRecordLifecycle(client: Acme_Patients_V1_MedicalRecordLifecycleService.Client(wrapping: mesh)),
            "vital-validation": PushProductNameVitalValidation(client: Acme_Careplans_V1_VitalValidationService.Client(wrapping: mesh)),
        ]
        try await route("vital-validation", entry, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: PushProductNameRecord, _ sinks: [String: any PushProductNameDestination]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.push(rec)
    }
}
