import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayMedicationTotalsID keeps of each CountMedicationTotals response.
struct RelayMedicationTotalsIDRecord {
    var correlationID: String
    var message: String
    var status: String
}

/// Sends records to acme.prescriptions.v1.MedicationLifecycleService.
struct RelayMedicationTotalsIDMedicationLifecycle {
    let client: Acme_Prescriptions_V1_MedicationLifecycleService.Client<MeshTransport>

    func forward(_ rec: RelayMedicationTotalsIDRecord) async throws {
        _ = try await client.suspendMedication(.with {
            $0.reason = rec.correlationID
            $0.details.reasonCode = rec.message
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationReportingService/CountMedicationTotals and hands what it keeps to acme.prescriptions.v1.MedicationLifecycleService.
enum RelayMedicationTotalsID {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Prescriptions_V1_MedicationReportingService.Client(wrapping: mesh)
        let response = try await source.countMedicationTotals(.with { $0.orderBy = "nightly-relay-medication-totals-id" })
        let rec = RelayMedicationTotalsIDRecord(
            correlationID: Kit.Text.normalize(response.result.correlationID),
            message: Kit.Text.normalize(response.result.message),
            status: response.result.status
        )
        try await RelayMedicationTotalsIDMedicationLifecycle(client: Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)).forward(rec)
    }
}
