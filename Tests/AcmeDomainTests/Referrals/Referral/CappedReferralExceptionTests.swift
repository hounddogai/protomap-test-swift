@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralExceptionTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newCappedReferralException("code-362", name: "name-521")
        #expect(item.status == Referrals.CappedReferralExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Referrals.newCappedReferralException("code-362", name: "name-521")
        try item.moveTo(Referrals.CappedReferralExceptionStatus.withdrawn)
        #expect(item.status == Referrals.CappedReferralExceptionStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newCappedReferralException("code-362", name: "name-521")
        item.status = Referrals.CappedReferralExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedReferralExceptionStatus.proposed) }
    }
}
