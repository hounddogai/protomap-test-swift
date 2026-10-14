import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RouteMedicationMessage keeps of each RenewMedication response.
struct RouteMedicationMessageRecord {
    var message: String
    var outcomeMessage: String
    var medicationID: String
    var status: String
}

/// Where RouteMedicationMessage hands each record.
protocol RouteMedicationMessageDestination {
    func apply(_ rec: RouteMedicationMessageRecord) async throws
}

/// Sends records to acme.documents.v1.DocumentService.
struct RouteMedicationMessageDocument: RouteMedicationMessageDestination {
    let client: Acme_Documents_V1_DocumentService.Client<MeshTransport>

    func apply(_ rec: RouteMedicationMessageRecord) async throws {
        _ = try await client.listDocuments(.with {
            $0.filter.region = rec.message
            $0.page.pageToken = rec.status
            $0.orderBy = rec.outcomeMessage
        })
    }
}

/// Hands records to acme.patients.v1.AllergyCalculationService.
struct RouteMedicationMessageAllergyCalculation: RouteMedicationMessageDestination {
    let client: Acme_Patients_V1_AllergyCalculationService.Client<MeshTransport>

    func apply(_ rec: RouteMedicationMessageRecord) async throws {
        _ = try await client.getAllergyRates(.with {
            $0.allergyID = rec.outcomeMessage
        })
    }
}

/// Reads acme.prescriptions.v1.MedicationLifecycleService/RenewMedication and hands what it keeps to the sink of its kind.
enum RouteMedicationMessage {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Prescriptions_V1_MedicationLifecycleService.Client(wrapping: mesh)
        let got = try await reader.renewMedication(.with { $0.medicationID = "primary-route-medication-message" })
        let row = RouteMedicationMessageRecord(
            message: got.result.message,
            outcomeMessage: got.outcome.message,
            medicationID: got.medication.medicationID,
            status: got.outcome.status
        )
        let sinks: [String: any RouteMedicationMessageDestination] = [
            "document": RouteMedicationMessageDocument(client: Acme_Documents_V1_DocumentService.Client(wrapping: mesh)),
            "allergy-calculation": RouteMedicationMessageAllergyCalculation(client: Acme_Patients_V1_AllergyCalculationService.Client(wrapping: mesh)),
        ]
        guard let sink = sinks[ProcessInfo.processInfo.environment["ROUTE_MEDICATION_MESSAGE_TARGET"] ?? ""] else {
            return
        }
        try await sink.apply(row)
    }
}
