@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotTemplateTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newSlotTemplate("code-639", label: "label-752")
        #expect(item.status == Referrals.SlotTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newSlotTemplate("code-639", label: "label-752")
        try item.moveTo(Referrals.SlotTemplateStatus.rejected)
        #expect(item.status == Referrals.SlotTemplateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newSlotTemplate("code-639", label: "label-752")
        item.status = Referrals.SlotTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotTemplateStatus.proposed) }
    }
}
