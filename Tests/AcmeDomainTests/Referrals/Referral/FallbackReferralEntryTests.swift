@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralEntryTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newFallbackReferralEntry("code-294", title: "title-658")
        #expect(item.status == Referrals.FallbackReferralEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newFallbackReferralEntry("code-294", title: "title-658")
        try item.moveTo(Referrals.FallbackReferralEntryStatus.ready)
        #expect(item.status == Referrals.FallbackReferralEntryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newFallbackReferralEntry("code-294", title: "title-658")
        item.status = Referrals.FallbackReferralEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackReferralEntryStatus.idle) }
    }
}
