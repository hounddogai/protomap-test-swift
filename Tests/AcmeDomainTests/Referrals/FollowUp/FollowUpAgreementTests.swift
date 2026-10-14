@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAgreementTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFollowUpAgreement("code-361", name: "name-198")
        #expect(item.status == Referrals.FollowUpAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newFollowUpAgreement("code-361", name: "name-198")
        try item.moveTo(Referrals.FollowUpAgreementStatus.suspended)
        #expect(item.status == Referrals.FollowUpAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFollowUpAgreement("code-361", name: "name-198")
        item.status = Referrals.FollowUpAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpAgreementStatus.draft) }
    }
}
