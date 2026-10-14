import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What SyncMedicalRecordRulesNumber keeps of each GetMedicalRecordRules response.
struct SyncMedicalRecordRulesNumberRecord {
    var number: String
    var correlationID: String
    var notes: String
}

/// Where SyncMedicalRecordRulesNumber hands each record.
protocol SyncMedicalRecordRulesNumberTarget {
    func forward(_ rec: SyncMedicalRecordRulesNumberRecord) async throws
}

/// Hands records to acme.inventory.v1.StockItemService.
struct SyncMedicalRecordRulesNumberStockItem: SyncMedicalRecordRulesNumberTarget {
    let client: Acme_Inventory_V1_StockItemService.Client<MeshTransport>

    func forward(_ rec: SyncMedicalRecordRulesNumberRecord) async throws {
        _ = try await client.cloneStockItem(.with {
            $0.requestID = rec.correlationID
            $0.stockItem.code = rec.notes
        })
    }
}

/// Sends records to acme.onboarding.v1.OnboardingPlanQueryService.
struct SyncMedicalRecordRulesNumberOnboardingPlanQuery: SyncMedicalRecordRulesNumberTarget {
    let client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client<MeshTransport>

    func forward(_ rec: SyncMedicalRecordRulesNumberRecord) async throws {
        _ = try await client.countOnboardingPlans(.with {
            $0.page.pageToken = rec.number
            $0.filter.region = rec.correlationID
            $0.filter.ownerID = rec.notes
        })
    }
}

/// Hands records to acme.patients.v1.MedicalRecordApprovalService.
struct SyncMedicalRecordRulesNumberMedicalRecordApproval: SyncMedicalRecordRulesNumberTarget {
    let client: Acme_Patients_V1_MedicalRecordApprovalService.Client<MeshTransport>

    func forward(_ rec: SyncMedicalRecordRulesNumberRecord) async throws {
        _ = try await client.rejectMedicalRecord(.with {
            $0.medicalRecord.number = rec.notes
            $0.details.comment = rec.correlationID
        })
    }
}

/// Reads acme.patients.v1.MedicalRecordValidationService/GetMedicalRecordRules and hands what it keeps to the sink of its kind.
enum SyncMedicalRecordRulesNumber {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patients_V1_MedicalRecordValidationService.Client(wrapping: mesh)
        let found = try await source.getMedicalRecordRules(.with { $0.medicalRecordID = "main-sync-medical-record-rules-number" })
        let row = SyncMedicalRecordRulesNumberRecord(
            number: Kit.Text.normalize(found.medicalRecord.number),
            correlationID: found.result.correlationID,
            notes: Kit.Text.normalize(found.medicalRecord.notes)
        )
        let sinks: [any SyncMedicalRecordRulesNumberTarget] = [
            SyncMedicalRecordRulesNumberStockItem(client: Acme_Inventory_V1_StockItemService.Client(wrapping: mesh)),
            SyncMedicalRecordRulesNumberOnboardingPlanQuery(client: Acme_Onboarding_V1_OnboardingPlanQueryService.Client(wrapping: mesh)),
            SyncMedicalRecordRulesNumberMedicalRecordApproval(client: Acme_Patients_V1_MedicalRecordApprovalService.Client(wrapping: mesh)),
        ]
        for sink in sinks {
            try await sink.forward(row)
        }
    }
}
