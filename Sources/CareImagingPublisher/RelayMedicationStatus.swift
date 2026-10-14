import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayMedicationStatus keeps of each ReinstateMedication response.
struct RelayMedicationStatusRecord {
    var status: String
    var code: String
    var correlationID: String
}

/// Where RelayMedicationStatus hands each record.
protocol RelayMedicationStatusTarget {
    func apply(_ rec: RelayMedicationStatusRecord) async throws
}

/// Sends records to acme.catalog.v1.ProductCalculationService.
struct RelayMedicationStatusProductCalculation: RelayMedicationStatusTarget {
    let client: Acme_Catalog_V1_ProductCalculationService.Client<MeshTransport>

    func apply(_ rec: RelayMedicationStatusRecord) async throws {
        _ = try await client.quoteProduct(.with {
            $0.details.currencyCode = rec.code
            $0.reason = rec.status
        })
    }
}

/// Writes records to acme.timekeeping.v1.TimesheetQueryService.
struct RelayMedicationStatusTimesheetQuery: RelayMedicationStatusTarget {
    let client: Acme_Timekeeping_V1_TimesheetQueryService.Client<MeshTransport>

    func apply(_ rec: RelayMedicationStatusRecord) async throws {
        _ = try await client.browseTimesheets(.with {
            $0.filter.region = rec.code
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationLifecycleService/ReinstateMedication and hands what it keeps to the sink of its kind.
enum RelayMedicationStatus {
    static func run(_ mesh: MeshClient) async throws {
        let origin = Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)
        let got = try await origin.reinstateMedication(.with { $0.medicationID = "main-relay-medication-status" })
        let record = RelayMedicationStatusRecord(
            status: got.outcome.status,
            code: got.medication.code,
            correlationID: got.result.correlationID
        )
        let sinks: [String: any RelayMedicationStatusTarget] = [
            "product-calculation": RelayMedicationStatusProductCalculation(client: Acme_Catalog_V1_ProductCalculationService.Client(wrapping: mesh)),
            "timesheet-query": RelayMedicationStatusTimesheetQuery(client: Acme_Timekeeping_V1_TimesheetQueryService.Client(wrapping: mesh)),
        ]
        for (kind, sink) in sinks {
            if kind != "product-calculation" {
                continue
            }
            try await sink.apply(record)
        }
    }
}
