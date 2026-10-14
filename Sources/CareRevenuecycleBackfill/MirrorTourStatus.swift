import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorTourStatus keeps of each DeleteTour response.
struct MirrorTourStatusRecord {
    var status: String
    var correlationID: String
}

/// Where MirrorTourStatus hands each record.
protocol MirrorTourStatusTarget {
    func write(_ rec: MirrorTourStatusRecord) async throws
}

/// Writes records to acme.appointments.v1.ProviderValidationService.
struct MirrorTourStatusProviderValidation: MirrorTourStatusTarget {
    let client: Acme_Appointments_V1_ProviderValidationService.Client<MeshTransport>

    func write(_ rec: MirrorTourStatusRecord) async throws {
        _ = try await client.lintProviders(.with {
            $0.providerID = rec.correlationID
        })
    }
}

/// Writes records to acme.boxoffice.v1.BoxOfficeSaleCalculationService.
struct MirrorTourStatusBoxOfficeSaleCalculation: MirrorTourStatusTarget {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client<MeshTransport>

    func write(_ rec: MirrorTourStatusRecord) async throws {
        let request = Acme_Boxoffice_V1_CompareBoxOfficeSaleOptionsRequest.with {
            $0.boxOfficeSale.boxOfficeSaleID = rec.status
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.compareBoxOfficeSaleOptions(request)
        }
    }
}

/// Hands records to acme.sponsorships.v1.SponsorCalculationService.
struct MirrorTourStatusSponsorCalculation: MirrorTourStatusTarget {
    let client: Acme_Sponsorships_V1_SponsorCalculationService.Client<MeshTransport>

    func write(_ rec: MirrorTourStatusRecord) async throws {
        let request = Acme_Sponsorships_V1_EstimateSponsorRequest.with {
            $0.details.currencyCode = rec.status
            $0.sponsor.sponsorID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.estimateSponsor(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorTourStatusLogOnly: MirrorTourStatusTarget {
    let logger = Logger(label: "acme.mirror-tour-status")

    func write(_ rec: MirrorTourStatusRecord) async throws {
        logger.info("No sink for record", metadata: ["status": .string(rec.status)])
    }
}

/// Reads acme.tours.v1.TourService/DeleteTour and hands what it keeps to the sink of its kind.
enum MirrorTourStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Tours_V1_TourService.Client(wrapping: mesh)
        let found = try await source.deleteTour(.with { $0.etag = "nightly-mirror-tour-status" })
        let record = MirrorTourStatusRecord(
            status: Kit.Text.normalize(found.result.status),
            correlationID: found.result.correlationID
        )
        try await dispatch("sponsor-calculation", record, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: MirrorTourStatusRecord, _ mesh: MeshClient) async throws {
        var write: (MirrorTourStatusRecord) async throws -> Void = MirrorTourStatusLogOnly().write
        switch kind {
        case "provider-validation":
            write = MirrorTourStatusProviderValidation(client: Acme_Appointments_V1_ProviderValidationService.Client(wrapping: mesh)).write
        case "box-office-sale-calculation":
            write = MirrorTourStatusBoxOfficeSaleCalculation(client: Acme_Boxoffice_V1_BoxOfficeSaleCalculationService.Client(wrapping: mesh)).write
        case "sponsor-calculation":
            write = MirrorTourStatusSponsorCalculation(client: Acme_Sponsorships_V1_SponsorCalculationService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
