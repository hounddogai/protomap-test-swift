@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualFollowUpRuleTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newManualFollowUpRule("code-593", name: "name-303")
        #expect(item.status == Referrals.ManualFollowUpRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newManualFollowUpRule("code-593", name: "name-303")
        try item.moveTo(Referrals.ManualFollowUpRuleStatus.pending)
        #expect(item.status == Referrals.ManualFollowUpRuleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newManualFollowUpRule("code-593", name: "name-303")
        item.status = Referrals.ManualFollowUpRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualFollowUpRuleStatus.draft) }
    }
}
