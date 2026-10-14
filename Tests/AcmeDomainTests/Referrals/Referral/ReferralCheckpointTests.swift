@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralCheckpointTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newReferralCheckpoint("code-875", name: "name-147")
        #expect(item.status == Referrals.ReferralCheckpointStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Referrals.newReferralCheckpoint("code-875", name: "name-147")
        try item.moveTo(Referrals.ReferralCheckpointStatus.ready)
        #expect(item.status == Referrals.ReferralCheckpointStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newReferralCheckpoint("code-875", name: "name-147")
        item.status = Referrals.ReferralCheckpointStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralCheckpointStatus.idle) }
    }
}
