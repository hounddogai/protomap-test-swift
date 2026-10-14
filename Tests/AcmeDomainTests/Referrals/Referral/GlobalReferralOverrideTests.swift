@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalReferralOverrideTests {
    @Test func startsInNew() throws {
        let item = Referrals.newGlobalReferralOverride("code-341", title: "title-67")
        #expect(item.status == Referrals.GlobalReferralOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newGlobalReferralOverride("code-341", title: "title-67")
        try item.moveTo(Referrals.GlobalReferralOverrideStatus.failed)
        #expect(item.status == Referrals.GlobalReferralOverrideStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newGlobalReferralOverride("code-341", title: "title-67")
        item.status = Referrals.GlobalReferralOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalReferralOverrideStatus.new) }
    }
}
