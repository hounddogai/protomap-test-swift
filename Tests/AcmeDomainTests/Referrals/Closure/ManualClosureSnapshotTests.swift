@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualClosureSnapshotTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newManualClosureSnapshot("code-376", label: "label-151")
        #expect(item.status == Referrals.ManualClosureSnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newManualClosureSnapshot("code-376", label: "label-151")
        try item.moveTo(Referrals.ManualClosureSnapshotStatus.approved)
        #expect(item.status == Referrals.ManualClosureSnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newManualClosureSnapshot("code-376", label: "label-151")
        item.status = Referrals.ManualClosureSnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualClosureSnapshotStatus.proposed) }
    }
}
