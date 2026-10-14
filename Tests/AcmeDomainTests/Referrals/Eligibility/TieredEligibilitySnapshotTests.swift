@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilitySnapshotTests {
    @Test func startsInNew() throws {
        let item = Referrals.newTieredEligibilitySnapshot("code-645", title: "title-741")
        #expect(item.status == Referrals.TieredEligibilitySnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newTieredEligibilitySnapshot("code-645", title: "title-741")
        try item.moveTo(Referrals.TieredEligibilitySnapshotStatus.done)
        #expect(item.status == Referrals.TieredEligibilitySnapshotStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newTieredEligibilitySnapshot("code-645", title: "title-741")
        item.status = Referrals.TieredEligibilitySnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredEligibilitySnapshotStatus.new) }
    }
}
