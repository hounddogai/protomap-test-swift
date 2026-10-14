@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpSnapshotTests {
    @Test func startsInNew() throws {
        let item = Referrals.newFollowUpSnapshot("code-729", label: "label-957")
        #expect(item.status == Referrals.FollowUpSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newFollowUpSnapshot("code-729", label: "label-957")
        try item.moveTo(Referrals.FollowUpSnapshotStatus.running)
        #expect(item.status == Referrals.FollowUpSnapshotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newFollowUpSnapshot("code-729", label: "label-957")
        item.status = Referrals.FollowUpSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FollowUpSnapshotStatus.new) }
    }
}
