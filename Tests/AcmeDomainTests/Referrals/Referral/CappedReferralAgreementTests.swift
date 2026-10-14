@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedReferralAgreementTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newCappedReferralAgreement("code-163", label: "label-806")
        #expect(item.status == Referrals.CappedReferralAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newCappedReferralAgreement("code-163", label: "label-806")
        try item.moveTo(Referrals.CappedReferralAgreementStatus.granted)
        #expect(item.status == Referrals.CappedReferralAgreementStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newCappedReferralAgreement("code-163", label: "label-806")
        item.status = Referrals.CappedReferralAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedReferralAgreementStatus.requested) }
    }
}
