@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityAgreementTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newEligibilityAgreement("code-648", title: "title-430")
        #expect(item.status == Referrals.EligibilityAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newEligibilityAgreement("code-648", title: "title-430")
        try item.moveTo(Referrals.EligibilityAgreementStatus.warming)
        #expect(item.status == Referrals.EligibilityAgreementStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newEligibilityAgreement("code-648", title: "title-430")
        item.status = Referrals.EligibilityAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityAgreementStatus.idle) }
    }
}
