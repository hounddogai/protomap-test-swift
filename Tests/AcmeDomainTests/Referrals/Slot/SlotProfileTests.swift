@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotProfileTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSlotProfile("code-267", title: "title-316")
        #expect(item.status == Referrals.SlotProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Referrals.newSlotProfile("code-267", title: "title-316")
        try item.moveTo(Referrals.SlotProfileStatus.approved)
        #expect(item.status == Referrals.SlotProfileStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSlotProfile("code-267", title: "title-316")
        item.status = Referrals.SlotProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotProfileStatus.proposed) }
    }
}
