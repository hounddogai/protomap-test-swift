@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalSubstitutionQuotaTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newSeasonalSubstitutionQuota("code-639", title: "title-254")
        #expect(item.status == Pharmacy.SeasonalSubstitutionQuotaStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newSeasonalSubstitutionQuota("code-639", title: "title-254")
        try item.moveTo(Pharmacy.SeasonalSubstitutionQuotaStatus.suspended)
        #expect(item.status == Pharmacy.SeasonalSubstitutionQuotaStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newSeasonalSubstitutionQuota("code-639", title: "title-254")
        item.status = Pharmacy.SeasonalSubstitutionQuotaStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalSubstitutionQuotaStatus.draft) }
    }
}
