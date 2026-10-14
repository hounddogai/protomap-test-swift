@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkCheckpointTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newNetworkCheckpoint("code-148", name: "name-777")
        #expect(item.status == Referrals.NetworkCheckpointStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newNetworkCheckpoint("code-148", name: "name-777")
        try item.moveTo(Referrals.NetworkCheckpointStatus.pending)
        #expect(item.status == Referrals.NetworkCheckpointStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newNetworkCheckpoint("code-148", name: "name-777")
        item.status = Referrals.NetworkCheckpointStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkCheckpointStatus.draft) }
    }
}
