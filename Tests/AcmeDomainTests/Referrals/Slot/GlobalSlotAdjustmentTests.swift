@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newGlobalSlotAdjustment("code-586", label: "label-624")
        #expect(item.status == Referrals.GlobalSlotAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newGlobalSlotAdjustment("code-586", label: "label-624")
        try item.moveTo(Referrals.GlobalSlotAdjustmentStatus.scheduled)
        #expect(item.status == Referrals.GlobalSlotAdjustmentStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newGlobalSlotAdjustment("code-586", label: "label-624")
        item.status = Referrals.GlobalSlotAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.GlobalSlotAdjustmentStatus.planned) }
    }
}
