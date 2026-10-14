@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAgreementTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newSlotAgreement("code-100", label: "label-649")
        #expect(item.status == Referrals.SlotAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newSlotAgreement("code-100", label: "label-649")
        try item.moveTo(Referrals.SlotAgreementStatus.warming)
        #expect(item.status == Referrals.SlotAgreementStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newSlotAgreement("code-100", label: "label-649")
        item.status = Referrals.SlotAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotAgreementStatus.idle) }
    }
}
