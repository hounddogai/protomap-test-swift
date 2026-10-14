@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilityTemplateTests {
    @Test func startsInNew() throws {
        let item = Referrals.newTieredEligibilityTemplate("code-655", label: "label-117")
        #expect(item.status == Referrals.TieredEligibilityTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Referrals.newTieredEligibilityTemplate("code-655", label: "label-117")
        try item.moveTo(Referrals.TieredEligibilityTemplateStatus.queued)
        #expect(item.status == Referrals.TieredEligibilityTemplateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newTieredEligibilityTemplate("code-655", label: "label-117")
        item.status = Referrals.TieredEligibilityTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredEligibilityTemplateStatus.new) }
    }
}
