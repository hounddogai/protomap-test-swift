@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityTemplateTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityTemplate("code-295", label: "label-307")
        #expect(item.status == Referrals.EligibilityTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newEligibilityTemplate("code-295", label: "label-307")
        try item.moveTo(Referrals.EligibilityTemplateStatus.done)
        #expect(item.status == Referrals.EligibilityTemplateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityTemplate("code-295", label: "label-307")
        item.status = Referrals.EligibilityTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityTemplateStatus.new) }
    }
}
