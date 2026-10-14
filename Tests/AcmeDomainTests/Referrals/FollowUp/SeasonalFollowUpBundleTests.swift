@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalFollowUpBundleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSeasonalFollowUpBundle("code-648", name: "name-354")
        #expect(item.status == Referrals.SeasonalFollowUpBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newSeasonalFollowUpBundle("code-648", name: "name-354")
        try item.moveTo(Referrals.SeasonalFollowUpBundleStatus.rejected)
        #expect(item.status == Referrals.SeasonalFollowUpBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSeasonalFollowUpBundle("code-648", name: "name-354")
        item.status = Referrals.SeasonalFollowUpBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalFollowUpBundleStatus.proposed) }
    }
}
