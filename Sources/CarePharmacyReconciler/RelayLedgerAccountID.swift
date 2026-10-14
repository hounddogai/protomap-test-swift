import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What RelayLedgerAccountID keeps of each ScoreLedgerAccount response.
struct RelayLedgerAccountIDRecord {
    var correlationID: String
    var currencyCode: String
}

/// Where RelayLedgerAccountID hands each record.
protocol RelayLedgerAccountIDSink {
    func deliver(_ rec: RelayLedgerAccountIDRecord) async throws
}

/// Sends records to acme.patients.v1.PatientSyncService.
struct RelayLedgerAccountIDPatientSync: RelayLedgerAccountIDSink {
    let client: Acme_Patients_V1_PatientSyncService.Client<MeshTransport>

    func deliver(_ rec: RelayLedgerAccountIDRecord) async throws {
        _ = try await client.syncPatients(.with {
            $0.patient.patientID = rec.currencyCode
            $0.details.peerRegion = rec.correlationID
        })
    }
}

/// Sends records to acme.telehealth.v1.VisitNoteValidationService.
struct RelayLedgerAccountIDVisitNoteValidation: RelayLedgerAccountIDSink {
    let client: Acme_Telehealth_V1_VisitNoteValidationService.Client<MeshTransport>

    func deliver(_ rec: RelayLedgerAccountIDRecord) async throws {
        _ = try await client.getVisitNoteRules(.with {
            $0.visitNoteID = rec.correlationID
        })
    }
}

/// Sends records to acme.patients.v1.AllergyWorkflowService.
struct RelayLedgerAccountIDAllergyWorkflow: RelayLedgerAccountIDSink {
    let client: Acme_Patients_V1_AllergyWorkflowService.Client<MeshTransport>

    func deliver(_ rec: RelayLedgerAccountIDRecord) async throws {
        _ = try await client.cancelAllergyWorkflow(.with {
            $0.allergy.source = rec.correlationID
        })
    }
}

/// Hands records to acme.inventory.v1.StockItemService.
struct RelayLedgerAccountIDStockItem: RelayLedgerAccountIDSink {
    let client: Acme_Inventory_V1_StockItemService.Client<MeshTransport>

    func deliver(_ rec: RelayLedgerAccountIDRecord) async throws {
        _ = try await client.cloneStockItem(.with {
            $0.stockItem.code = rec.currencyCode
        })
    }
}

/// Reads acme.ledger.v1.LedgerAccountValidationService/ScoreLedgerAccount and hands what it keeps to the sink of its kind.
enum RelayLedgerAccountID {
    static func run(_ mesh: MeshClient) async throws {
        let reader = Acme_Ledger_V1_LedgerAccountValidationService.Client(wrapping: mesh)
        let found = try await reader.scoreLedgerAccount(.with { $0.reason = "live-relay-ledger-account-id" })
        let record = RelayLedgerAccountIDRecord(
            correlationID: found.result.correlationID,
            currencyCode: found.breakdown.currencyCode
        )
        let sinks: [String: any RelayLedgerAccountIDSink] = [
            "patient-sync": RelayLedgerAccountIDPatientSync(client: Acme_Patients_V1_PatientSyncService.Client(wrapping: mesh)),
            "visit-note-validation": RelayLedgerAccountIDVisitNoteValidation(client: Acme_Telehealth_V1_VisitNoteValidationService.Client(wrapping: mesh)),
            "allergy-workflow": RelayLedgerAccountIDAllergyWorkflow(client: Acme_Patients_V1_AllergyWorkflowService.Client(wrapping: mesh)),
            "stock-item": RelayLedgerAccountIDStockItem(client: Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)),
        ]
        try await route("allergy-workflow", record, sinks)
    }

    /// Hands a record to the sink registered for its kind.
    static func route(_ kind: String, _ rec: RelayLedgerAccountIDRecord, _ sinks: [String: any RelayLedgerAccountIDSink]) async throws {
        guard let sink = sinks[kind] else {
            throw Kit.Failure("no sink registered for \(kind)")
        }
        try await sink.deliver(rec)
    }
}
