@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkSnapshotTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newNetworkSnapshot("code-999", label: "label-276")
        #expect(item.status == Referrals.NetworkSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newNetworkSnapshot("code-999", label: "label-276")
        try item.moveTo(Referrals.NetworkSnapshotStatus.approved)
        #expect(item.status == Referrals.NetworkSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newNetworkSnapshot("code-999", label: "label-276")
        item.status = Referrals.NetworkSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkSnapshotStatus.proposed) }
    }
}
