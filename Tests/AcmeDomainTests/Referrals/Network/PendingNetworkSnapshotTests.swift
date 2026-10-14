@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkSnapshotTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newPendingNetworkSnapshot("code-220", title: "title-599")
        #expect(item.status == Referrals.PendingNetworkSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newPendingNetworkSnapshot("code-220", title: "title-599")
        try item.moveTo(Referrals.PendingNetworkSnapshotStatus.approved)
        #expect(item.status == Referrals.PendingNetworkSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newPendingNetworkSnapshot("code-220", title: "title-599")
        item.status = Referrals.PendingNetworkSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PendingNetworkSnapshotStatus.proposed) }
    }
}
