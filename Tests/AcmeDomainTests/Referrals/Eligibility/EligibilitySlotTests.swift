@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySlotTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newEligibilitySlot("code-648", name: "name-217")
        #expect(item.status == Referrals.EligibilitySlotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newEligibilitySlot("code-648", name: "name-217")
        try item.moveTo(Referrals.EligibilitySlotStatus.reopened)
        #expect(item.status == Referrals.EligibilitySlotStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newEligibilitySlot("code-648", name: "name-217")
        item.status = Referrals.EligibilitySlotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilitySlotStatus.`open`) }
    }
}
