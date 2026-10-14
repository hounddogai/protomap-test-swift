@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalEligibilityRecordTests {
    @Test func startsInNew() throws {
        let item = Referrals.newSeasonalEligibilityRecord("code-324", title: "title-267")
        #expect(item.status == Referrals.SeasonalEligibilityRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newSeasonalEligibilityRecord("code-324", title: "title-267")
        try item.moveTo(Referrals.SeasonalEligibilityRecordStatus.failed)
        #expect(item.status == Referrals.SeasonalEligibilityRecordStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newSeasonalEligibilityRecord("code-324", title: "title-267")
        item.status = Referrals.SeasonalEligibilityRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalEligibilityRecordStatus.new) }
    }
}
