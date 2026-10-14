@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotRequestTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newDefaultSlotRequest("code-446", label: "label-938")
        #expect(item.status == Referrals.DefaultSlotRequestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newDefaultSlotRequest("code-446", label: "label-938")
        try item.moveTo(Referrals.DefaultSlotRequestStatus.rejected)
        #expect(item.status == Referrals.DefaultSlotRequestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newDefaultSlotRequest("code-446", label: "label-938")
        item.status = Referrals.DefaultSlotRequestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.DefaultSlotRequestStatus.proposed) }
    }
}
