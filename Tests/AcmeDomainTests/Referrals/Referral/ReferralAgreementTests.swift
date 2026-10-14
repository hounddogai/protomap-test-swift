@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralAgreementTests {
    @Test func startsInNew() throws {
        let item = Referrals.newReferralAgreement("code-895", label: "label-831")
        #expect(item.status == Referrals.ReferralAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newReferralAgreement("code-895", label: "label-831")
        try item.moveTo(Referrals.ReferralAgreementStatus.queued)
        #expect(item.status == Referrals.ReferralAgreementStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newReferralAgreement("code-895", label: "label-831")
        item.status = Referrals.ReferralAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralAgreementStatus.new) }
    }
}
