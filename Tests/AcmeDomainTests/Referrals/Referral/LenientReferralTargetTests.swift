@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientReferralTargetTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newLenientReferralTarget("code-577", label: "label-115")
        #expect(item.status == Referrals.LenientReferralTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newLenientReferralTarget("code-577", label: "label-115")
        try item.moveTo(Referrals.LenientReferralTargetStatus.ready)
        #expect(item.status == Referrals.LenientReferralTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newLenientReferralTarget("code-577", label: "label-115")
        item.status = Referrals.LenientReferralTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientReferralTargetStatus.idle) }
    }
}
