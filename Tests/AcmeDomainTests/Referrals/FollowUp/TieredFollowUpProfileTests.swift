@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpProfileTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newTieredFollowUpProfile("code-137", label: "label-892")
        #expect(item.status == Referrals.TieredFollowUpProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newTieredFollowUpProfile("code-137", label: "label-892")
        try item.moveTo(Referrals.TieredFollowUpProfileStatus.pending)
        #expect(item.status == Referrals.TieredFollowUpProfileStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newTieredFollowUpProfile("code-137", label: "label-892")
        item.status = Referrals.TieredFollowUpProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpProfileStatus.draft) }
    }
}
