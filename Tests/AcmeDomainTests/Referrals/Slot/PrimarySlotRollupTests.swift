@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotRollupTests {
    @Test func startsInNew() throws {
        let item = Referrals.newPrimarySlotRollup("code-407", name: "name-63")
        #expect(item.status == Referrals.PrimarySlotRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newPrimarySlotRollup("code-407", name: "name-63")
        try item.moveTo(Referrals.PrimarySlotRollupStatus.running)
        #expect(item.status == Referrals.PrimarySlotRollupStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newPrimarySlotRollup("code-407", name: "name-63")
        item.status = Referrals.PrimarySlotRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.PrimarySlotRollupStatus.new) }
    }
}
