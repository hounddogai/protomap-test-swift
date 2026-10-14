import AcmeContracts
import AcmePlatform
import Foundation
import GRPCCore
import Logging

/// What BackfillCareInboxEventsStatus keeps of each ReplayCareInboxEvents response.
struct BackfillCareInboxEventsStatusRecord {
    var status: String
    var notes: String
    var referenceID: String
    var message: String
}

/// Where BackfillCareInboxEventsStatus hands each record.
protocol BackfillCareInboxEventsStatusWriter {
    func push(_ rec: BackfillCareInboxEventsStatusRecord) async throws
}

/// Passes records to acme.patients.v1.AllergyApprovalService.
struct BackfillCareInboxEventsStatusAllergyApproval: BackfillCareInboxEventsStatusWriter {
    let client: Acme_Patients_V1_AllergyApprovalService.Client<MeshTransport>

    func push(_ rec: BackfillCareInboxEventsStatusRecord) async throws {
        _ = try await client.delegateAllergyApproval(.with {
            $0.allergy.source = rec.referenceID
        })
    }
}

/// Hands records to acme.promotions.v1.PromotionCalculationService.
struct BackfillCareInboxEventsStatusPromotionCalculation: BackfillCareInboxEventsStatusWriter {
    let client: Acme_Promotions_V1_PromotionCalculationService.Client<MeshTransport>

    func push(_ rec: BackfillCareInboxEventsStatusRecord) async throws {
        _ = try await client.calculatePromotion(.with {
            $0.promotion.promotionID = rec.referenceID
        })
    }
}

/// Sends records to acme.boxoffice.v1.BoxOfficeSaleQueryService.
struct BackfillCareInboxEventsStatusBoxOfficeSaleQuery: BackfillCareInboxEventsStatusWriter {
    let client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client<MeshTransport>

    func push(_ rec: BackfillCareInboxEventsStatusRecord) async throws {
        let request = Acme_Boxoffice_V1_CountBoxOfficeSalesRequest.with {
            $0.filter.region = rec.notes
        }
        _ = try await RPCOperations.call(request) { request in
            try await client.countBoxOfficeSales(request)
        }
    }
}

/// Reads acme.patientapp.v1.CareInboxIntegrationService/ReplayCareInboxEvents and hands what it keeps to the sink of its kind.
enum BackfillCareInboxEventsStatus {
    static func run(_ mesh: MeshClient) async throws {
        let source = Acme_Patientapp_V1_CareInboxIntegrationService.Client(wrapping: mesh)
        let response = try await source.replayCareInboxEvents(.with { $0.reason = "primary-backfill-care-inbox-events-status" })
        let row = BackfillCareInboxEventsStatusRecord(
            status: response.outcome.status,
            notes: Kit.Text.normalize(response.careInbox.notes),
            referenceID: response.outcome.referenceID,
            message: Kit.Text.normalize(response.result.message)
        )
        try await act("promotion-calculation", row, mesh)
    }

    /// Runs the action registered for a kind.
    static func act(_ kind: String, _ rec: BackfillCareInboxEventsStatusRecord, _ mesh: MeshClient) async throws {
        let actions: [String: () async throws -> Void] = [
            "allergy-approval": { try await BackfillCareInboxEventsStatusAllergyApproval(client: Acme_Patients_V1_AllergyApprovalService.Client(wrapping: mesh)).push(rec) },
            "promotion-calculation": { try await BackfillCareInboxEventsStatusPromotionCalculation(client: Acme_Promotions_V1_PromotionCalculationService.Client(wrapping: mesh)).push(rec) },
            "box-office-sale-query": { try await BackfillCareInboxEventsStatusBoxOfficeSaleQuery(client: Acme_Boxoffice_V1_BoxOfficeSaleQueryService.Client(wrapping: mesh)).push(rec) },
        ]
        guard let action = actions[kind] else {
            throw Kit.Failure("no action for \(kind)")
        }
        try await action()
    }
}
