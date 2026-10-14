@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackNetworkSnapshotTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFallbackNetworkSnapshot("code-820", title: "title-45")
        #expect(item.status == Referrals.FallbackNetworkSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newFallbackNetworkSnapshot("code-820", title: "title-45")
        try item.moveTo(Referrals.FallbackNetworkSnapshotStatus.granted)
        #expect(item.status == Referrals.FallbackNetworkSnapshotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFallbackNetworkSnapshot("code-820", title: "title-45")
        item.status = Referrals.FallbackNetworkSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackNetworkSnapshotStatus.requested) }
    }
}
