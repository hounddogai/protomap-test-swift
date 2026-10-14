@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilitySlotTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newStrictEligibilitySlot("code-701", name: "name-197")
        #expect(item.status == Referrals.StrictEligibilitySlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newStrictEligibilitySlot("code-701", name: "name-197")
        try item.moveTo(Referrals.StrictEligibilitySlotStatus.active)
        #expect(item.status == Referrals.StrictEligibilitySlotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newStrictEligibilitySlot("code-701", name: "name-197")
        item.status = Referrals.StrictEligibilitySlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictEligibilitySlotStatus.draft) }
    }
}
