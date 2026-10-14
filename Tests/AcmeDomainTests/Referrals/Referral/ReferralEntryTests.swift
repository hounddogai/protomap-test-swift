@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralEntryTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newReferralEntry("code-993", name: "name-143")
        #expect(item.status == Referrals.ReferralEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newReferralEntry("code-993", name: "name-143")
        try item.moveTo(Referrals.ReferralEntryStatus.ready)
        #expect(item.status == Referrals.ReferralEntryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newReferralEntry("code-993", name: "name-143")
        item.status = Referrals.ReferralEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralEntryStatus.idle) }
    }
}
