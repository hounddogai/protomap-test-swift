@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultReferralAgreementTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newDefaultReferralAgreement("code-566", name: "name-890")
        #expect(item.status == Referrals.DefaultReferralAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newDefaultReferralAgreement("code-566", name: "name-890")
        try item.moveTo(Referrals.DefaultReferralAgreementStatus.approved)
        #expect(item.status == Referrals.DefaultReferralAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newDefaultReferralAgreement("code-566", name: "name-890")
        item.status = Referrals.DefaultReferralAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultReferralAgreementStatus.proposed) }
    }
}
