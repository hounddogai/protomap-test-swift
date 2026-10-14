@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredReferralTemplateTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newTieredReferralTemplate("code-572", label: "label-798")
        #expect(item.status == Referrals.TieredReferralTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newTieredReferralTemplate("code-572", label: "label-798")
        try item.moveTo(Referrals.TieredReferralTemplateStatus.pending)
        #expect(item.status == Referrals.TieredReferralTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newTieredReferralTemplate("code-572", label: "label-798")
        item.status = Referrals.TieredReferralTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredReferralTemplateStatus.draft) }
    }
}
