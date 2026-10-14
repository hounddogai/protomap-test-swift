import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What MirrorVenueMessage keeps of each PeekVenue response.
struct MirrorVenueMessageRecord {
    var message: String
    var venueID: String
}

/// Where MirrorVenueMessage hands each record.
protocol MirrorVenueMessageTarget {
    func write(_ rec: MirrorVenueMessageRecord) async throws
}

/// Writes records to acme.prescriptions.v1.PrescriptionQueryService.
struct MirrorVenueMessagePrescriptionQuery: MirrorVenueMessageTarget {
    let client: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>

    func write(_ rec: MirrorVenueMessageRecord) async throws {
        let request = Acme_Prescriptions_V1_BrowsePrescriptionsRequest.with {
            $0.filter.ownerID = rec.message
            $0.orderBy = rec.venueID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.browsePrescriptions(request)
        }
    }
}

/// Passes records to acme.deliveries.v1.DeliveryService.
struct MirrorVenueMessageDelivery: MirrorVenueMessageTarget {
    let client: Acme_Deliveries_V1_DeliveryService.Client<MeshTransport>

    func write(_ rec: MirrorVenueMessageRecord) async throws {
        _ = try await client.listDeliveries(.with {
            $0.filter.region = rec.message
            $0.page.pageToken = rec.venueID
        })
    }
}

/// Sends records to acme.patients.v1.MedicalRecordSyncService.
struct MirrorVenueMessageMedicalRecordSync: MirrorVenueMessageTarget {
    let client: Acme_Patients_V1_MedicalRecordSyncService.Client<MeshTransport>

    func write(_ rec: MirrorVenueMessageRecord) async throws {
        _ = try await client.getMedicalRecordSyncState(.with {
            $0.medicalRecordID = rec.message
        })
    }
}

/// Only logs, for kinds no service takes yet.
struct MirrorVenueMessageLogOnly: MirrorVenueMessageTarget {
    let logger = Logger(label: "acme.mirror-venue-message")

    func write(_ rec: MirrorVenueMessageRecord) async throws {
        logger.info("No sink for record", metadata: ["message": .string(rec.message)])
    }
}

/// Reads acme.venues.v1.VenueQueryService/PeekVenue and hands what it keeps to the sink of its kind.
enum MirrorVenueMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Venues_V1_VenueQueryService.Client(wrapping: mesh)
        let found = try await reader.peekVenue(.with { $0.venueID = "main-mirror-venue-message" })
        let entry = MirrorVenueMessageRecord(
            message: found.result.message,
            venueID: found.venue.venueID
        )
        try await dispatch("prescription-query", entry, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: MirrorVenueMessageRecord, _ mesh: MeshClient) async throws {
        var write: (MirrorVenueMessageRecord) async throws -> Void = MirrorVenueMessageLogOnly().write
        switch kind {
        case "prescription-query":
            write = MirrorVenueMessagePrescriptionQuery(client: Acme_Prescriptions_V1_PrescriptionQueryService.Client(wrapping: mesh)).write
        case "delivery":
            write = MirrorVenueMessageDelivery(client: Acme_Deliveries_V1_DeliveryService.Client(wrapping: mesh)).write
        case "medical-record-sync":
            write = MirrorVenueMessageMedicalRecordSync(client: Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: mesh)).write
        default:
            break
        }
        try await write(rec)
    }
}
