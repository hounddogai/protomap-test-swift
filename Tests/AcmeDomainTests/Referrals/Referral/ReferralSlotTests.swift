@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsReferralSlotTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newReferralSlot("code-289", title: "title-856")
        #expect(item.status == Referrals.ReferralSlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newReferralSlot("code-289", title: "title-856")
        try item.moveTo(Referrals.ReferralSlotStatus.approved)
        #expect(item.status == Referrals.ReferralSlotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newReferralSlot("code-289", title: "title-856")
        item.status = Referrals.ReferralSlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ReferralSlotStatus.proposed) }
    }
}
