import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncTourID keeps of each LookupTour response.
struct SyncTourIDRecord {
    var tourID: String
    var message: String
    var status: String
    var title: String
}

/// Where SyncTourID hands each record.
protocol SyncTourIDTarget {
    func send(_ rec: SyncTourIDRecord) async throws
}

/// Sends records to acme.patients.v1.AllergyImportService.
struct SyncTourIDAllergyImport: SyncTourIDTarget {
    let client: Acme_Patients_V1_AllergyImportService.Client<MeshTransport>

    func send(_ rec: SyncTourIDRecord) async throws {
        _ = try await client.mapAllergyImportColumns(.with {
            $0.allergy.kind = rec.status
            $0.allergy.allergyID = rec.title
            $0.details.locale = rec.message
        })
    }
}

/// Writes records to acme.patients.v1.AllergyCalculationService.
struct SyncTourIDAllergyCalculation: SyncTourIDTarget {
    let client: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>

    func send(_ rec: SyncTourIDRecord) async throws {
        let request = Acme_Patients_V1_CalculateAllergyRequest.with {
            $0.allergy.allergyID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.calculateAllergy(request)
        }
    }
}

/// Hands records to acme.search.v1.SearchIndexValidationService.
struct SyncTourIDSearchIndexValidation: SyncTourIDTarget {
    let client: Acme_Search_V1_SearchIndexValidationService.Client<MeshTransport>

    func send(_ rec: SyncTourIDRecord) async throws {
        let request = Acme_Search_V1_LintSearchIndexesRequest.with {
            $0.searchIndex.searchIndexID = rec.tourID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.lintSearchIndexes(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SyncTourIDLogOnly: SyncTourIDTarget {
    let logger = Logger(label: "acme.sync-tour-id")

    func send(_ rec: SyncTourIDRecord) async throws {
        logger.info("No sink for record", metadata: ["tourID": .string(rec.tourID)])
    }
}

/// Reads acme.tours.v1.TourQueryService/LookupTour and hands what it keeps to the sink of its kind.
enum SyncTourID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Tours_V1_TourQueryService.Client(wrapping: mesh)
        let response = try await source.lookupTour(.with { $0.tourID = "current-sync-tour-id" })
        let rec = SyncTourIDRecord(
            tourID: response.tour.tourID,
            message: Kit.Text.normalize(response.result.message),
            status: response.result.status,
            title: response.tour.title
        )
        try await dispatch("search-index-validation", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SyncTourIDRecord, _ mesh: MeshClient) async throws {
        var write: (SyncTourIDRecord) async throws -> Void = SyncTourIDLogOnly().send
        switch kind {
        case "allergy-import":
            write = SyncTourIDAllergyImport(client: Acme_Patients_V1_AllergyImportService.Client(wrapping: mesh)).send
        case "allergy-calculation":
            write = SyncTourIDAllergyCalculation(client: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)).send
        case "search-index-validation":
            write = SyncTourIDSearchIndexValidation(client: Acme_Search_V1_SearchIndexValidationService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
