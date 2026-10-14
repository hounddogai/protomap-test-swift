@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilitySlotTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newCappedEligibilitySlot("code-781", title: "title-927")
        #expect(item.status == Referrals.CappedEligibilitySlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Referrals.newCappedEligibilitySlot("code-781", title: "title-927")
        try item.moveTo(Referrals.CappedEligibilitySlotStatus.scheduled)
        #expect(item.status == Referrals.CappedEligibilitySlotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newCappedEligibilitySlot("code-781", title: "title-927")
        item.status = Referrals.CappedEligibilitySlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.CappedEligibilitySlotStatus.planned) }
    }
}
