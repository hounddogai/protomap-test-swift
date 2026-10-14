@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotDraftTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotDraft("code-533", label: "label-516")
        #expect(item.status == Referrals.SlotDraftStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newSlotDraft("code-533", label: "label-516")
        try item.moveTo(Referrals.SlotDraftStatus.inReview)
        #expect(item.status == Referrals.SlotDraftStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotDraft("code-533", label: "label-516")
        item.status = Referrals.SlotDraftStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotDraftStatus.`open`) }
    }
}
