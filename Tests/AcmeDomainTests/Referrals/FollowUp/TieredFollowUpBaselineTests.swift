@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBaselineTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newTieredFollowUpBaseline("code-752", title: "title-800")
        #expect(item.status == Referrals.TieredFollowUpBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newTieredFollowUpBaseline("code-752", title: "title-800")
        try item.moveTo(Referrals.TieredFollowUpBaselineStatus.rejected)
        #expect(item.status == Referrals.TieredFollowUpBaselineStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newTieredFollowUpBaseline("code-752", title: "title-800")
        item.status = Referrals.TieredFollowUpBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpBaselineStatus.proposed) }
    }
}
