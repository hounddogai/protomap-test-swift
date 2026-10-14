@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotCheckpointTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newRollingSlotCheckpoint("code-753", name: "name-34")
        #expect(item.status == Referrals.RollingSlotCheckpointStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newRollingSlotCheckpoint("code-753", name: "name-34")
        try item.moveTo(Referrals.RollingSlotCheckpointStatus.inProgress)
        #expect(item.status == Referrals.RollingSlotCheckpointStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newRollingSlotCheckpoint("code-753", name: "name-34")
        item.status = Referrals.RollingSlotCheckpointStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RollingSlotCheckpointStatus.planned) }
    }
}
