@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralRollupTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newCappedReferralRollup("code-421", title: "title-276")
        #expect(item.status == Referrals.CappedReferralRollupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newCappedReferralRollup("code-421", title: "title-276")
        try item.moveTo(Referrals.CappedReferralRollupStatus.validated)
        #expect(item.status == Referrals.CappedReferralRollupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newCappedReferralRollup("code-421", title: "title-276")
        item.status = Referrals.CappedReferralRollupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedReferralRollupStatus.created) }
    }
}
