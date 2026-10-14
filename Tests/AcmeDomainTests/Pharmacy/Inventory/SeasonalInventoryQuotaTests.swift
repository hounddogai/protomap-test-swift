@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryQuotaTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newSeasonalInventoryQuota("code-571", label: "label-713")
        #expect(item.status == Pharmacy.SeasonalInventoryQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newSeasonalInventoryQuota("code-571", label: "label-713")
        try item.moveTo(Pharmacy.SeasonalInventoryQuotaStatus.inProgress)
        #expect(item.status == Pharmacy.SeasonalInventoryQuotaStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newSeasonalInventoryQuota("code-571", label: "label-713")
        item.status = Pharmacy.SeasonalInventoryQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalInventoryQuotaStatus.planned) }
    }
}
