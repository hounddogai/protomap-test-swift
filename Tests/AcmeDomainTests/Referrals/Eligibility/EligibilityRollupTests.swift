@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityRollupTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityRollup("code-507", title: "title-351")
        #expect(item.status == Referrals.EligibilityRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newEligibilityRollup("code-507", title: "title-351")
        try item.moveTo(Referrals.EligibilityRollupStatus.failed)
        #expect(item.status == Referrals.EligibilityRollupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityRollup("code-507", title: "title-351")
        item.status = Referrals.EligibilityRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityRollupStatus.new) }
    }
}
