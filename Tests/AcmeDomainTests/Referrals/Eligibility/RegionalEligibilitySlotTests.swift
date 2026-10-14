@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilitySlotTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newRegionalEligibilitySlot("code-227", label: "label-924")
        #expect(item.status == Referrals.RegionalEligibilitySlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Referrals.newRegionalEligibilitySlot("code-227", label: "label-924")
        try item.moveTo(Referrals.RegionalEligibilitySlotStatus.stopped)
        #expect(item.status == Referrals.RegionalEligibilitySlotStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newRegionalEligibilitySlot("code-227", label: "label-924")
        item.status = Referrals.RegionalEligibilitySlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalEligibilitySlotStatus.idle) }
    }
}
