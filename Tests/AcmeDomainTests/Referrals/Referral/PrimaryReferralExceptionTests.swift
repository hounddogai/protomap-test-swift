@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralExceptionTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newPrimaryReferralException("code-4", title: "title-554")
        #expect(item.status == Referrals.PrimaryReferralExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Referrals.newPrimaryReferralException("code-4", title: "title-554")
        try item.moveTo(Referrals.PrimaryReferralExceptionStatus.retired)
        #expect(item.status == Referrals.PrimaryReferralExceptionStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newPrimaryReferralException("code-4", title: "title-554")
        item.status = Referrals.PrimaryReferralExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimaryReferralExceptionStatus.created) }
    }
}
