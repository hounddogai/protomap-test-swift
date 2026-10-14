import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SettleMedicalRecordSyncStateID keeps of each GetMedicalRecordSyncState response.
struct SettleMedicalRecordSyncStateIDRecord {
    var medicalRecordID: String
    var correlationID: String
}

/// Where SettleMedicalRecordSyncStateID hands each record.
protocol SettleMedicalRecordSyncStateIDTarget {
    func send(_ rec: SettleMedicalRecordSyncStateIDRecord) async throws
}

/// Passes records to acme.venues.v1.VenueService.
struct SettleMedicalRecordSyncStateIDVenue: SettleMedicalRecordSyncStateIDTarget {
    let client: Acme_Venues_V1_VenueService.Client<MeshTransport>

    func send(_ rec: SettleMedicalRecordSyncStateIDRecord) async throws {
        let request = Acme_Venues_V1_CloneVenueRequest.with {
            $0.venue.code = rec.correlationID
            $0.venue.venueID = rec.medicalRecordID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.cloneVenue(request)
        }
    }
}

/// Passes records to acme.prescriptions.v1.PrescriptionQueryService.
struct SettleMedicalRecordSyncStateIDPrescriptionQuery: SettleMedicalRecordSyncStateIDTarget {
    let client: Acme_Prescriptions_V1_PrescriptionQueryService.Client<MeshTransport>

    func send(_ rec: SettleMedicalRecordSyncStateIDRecord) async throws {
        let request = Acme_Prescriptions_V1_PeekPrescriptionRequest.with {
            $0.prescriptionID = rec.correlationID
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.peekPrescription(request)
        }
    }
}

/// Only logs, for kinds no service takes yet.
struct SettleMedicalRecordSyncStateIDLogOnly: SettleMedicalRecordSyncStateIDTarget {
    let logger = Logger(label: "acme.settle-medical-record-sync-state-id")

    func send(_ rec: SettleMedicalRecordSyncStateIDRecord) async throws {
        logger.info("No sink for record", metadata: ["medicalRecordID": .string(rec.medicalRecordID)])
    }
}

/// Reads acme.patients.v1.MedicalRecordSyncService/GetMedicalRecordSyncState and hands what it keeps to the sink of its kind.
enum SettleMedicalRecordSyncStateID {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Patients_V1_MedicalRecordSyncService.Client(wrapping: mesh)
        let reply = try await origin.getMedicalRecordSyncState(.with { $0.medicalRecordID = "main-settle-medical-record-sync-state-id" })
        let rec = SettleMedicalRecordSyncStateIDRecord(
            medicalRecordID: reply.medicalRecord.medicalRecordID,
            correlationID: Kit.Text.normalize(reply.result.correlationID)
        )
        try await dispatch("venue", rec, mesh)
    }

    /// Picks the writer of a kind and runs it.
    static func dispatch(_ kind: String, _ rec: SettleMedicalRecordSyncStateIDRecord, _ mesh: MeshClient) async throws {
        var write: (SettleMedicalRecordSyncStateIDRecord) async throws -> Void = SettleMedicalRecordSyncStateIDLogOnly().send
        switch kind {
        case "venue":
            write = SettleMedicalRecordSyncStateIDVenue(client: Acme_Venues_V1_VenueService.Client(wrapping: mesh)).send
        case "prescription-query":
            write = SettleMedicalRecordSyncStateIDPrescriptionQuery(client: Acme_Prescriptions_V1_PrescriptionQueryService.Client(wrapping: mesh)).send
        default:
            break
        }
        try await write(rec)
    }
}
