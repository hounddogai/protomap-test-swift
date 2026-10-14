@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictFollowUpTemplateTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newStrictFollowUpTemplate("code-307", label: "label-15")
        #expect(item.status == Referrals.StrictFollowUpTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newStrictFollowUpTemplate("code-307", label: "label-15")
        try item.moveTo(Referrals.StrictFollowUpTemplateStatus.expired)
        #expect(item.status == Referrals.StrictFollowUpTemplateStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newStrictFollowUpTemplate("code-307", label: "label-15")
        item.status = Referrals.StrictFollowUpTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictFollowUpTemplateStatus.requested) }
    }
}
