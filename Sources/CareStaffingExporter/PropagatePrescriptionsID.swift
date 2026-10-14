import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What PropagatePrescriptionsID keeps of each SyncPrescriptions response.
struct PropagatePrescriptionsIDRecord {
    var referenceID: String
    var prescriptionID: String
    var correlationID: String
}

/// Where PropagatePrescriptionsID hands each record.
protocol PropagatePrescriptionsIDWriter {
    func send(_ rec: PropagatePrescriptionsIDRecord) async throws
}

/// Writes records to acme.tours.v1.TourService.
struct PropagatePrescriptionsIDTour: PropagatePrescriptionsIDWriter {
    let client: Acme_Tours_V1_TourService.Client<MeshTransport>

    func send(_ rec: PropagatePrescriptionsIDRecord) async throws {
        _ = try await client.searchTours(.with {
            $0.filter.region = rec.correlationID
            $0.filter.ownerID = rec.prescriptionID
            $0.filter.query = rec.referenceID
        })
    }
}

/// Sends records to acme.concessions.v1.ConcessionStandCalculationService.
struct PropagatePrescriptionsIDConcessionStandCalculation: PropagatePrescriptionsIDWriter {
    let client: Acme_Concessions_V1_ConcessionStandCalculationService.Client<MeshTransport>

    func send(_ rec: PropagatePrescriptionsIDRecord) async throws {
        _ = try await client.compareConcessionStandOptions(.with {
            $0.details.currencyCode = rec.prescriptionID
            $0.concessionStand.concessionStandID = rec.referenceID
            $0.concessionStandID = rec.correlationID
        })
    }
}

/// Reads acme.prescriptions.v1.PrescriptionSyncService/SyncPrescriptions and hands what it keeps to the sink of its kind.
enum PropagatePrescriptionsID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_PrescriptionSyncService.Client(wrapping: mesh)
        let reply = try await reader.syncPrescriptions(.with { $0.reason = "default-propagate-prescriptions-id" })
        let row = PropagatePrescriptionsIDRecord(
            referenceID: reply.outcome.referenceID,
            prescriptionID: reply.prescription.prescriptionID,
            correlationID: reply.result.correlationID
        )
        let sinks: [String: any PropagatePrescriptionsIDWriter] = [
            "tour": PropagatePrescriptionsIDTour(client: Acme_Tours_V1_TourService.Client(wrapping: mesh)),
            "concession-stand-calculation": PropagatePrescriptionsIDConcessionStandCalculation(client: Acme_Concessions_V1_ConcessionStandCalculationService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "tour" {
                continue
            }
            try await sink.send(row)
        }
    }
}
