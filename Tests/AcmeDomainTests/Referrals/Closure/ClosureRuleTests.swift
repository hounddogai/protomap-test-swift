@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureRuleTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureRule("code-64", label: "label-324")
        #expect(item.status == Referrals.ClosureRuleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Referrals.newClosureRule("code-64", label: "label-324")
        try item.moveTo(Referrals.ClosureRuleStatus.suspended)
        #expect(item.status == Referrals.ClosureRuleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureRule("code-64", label: "label-324")
        item.status = Referrals.ClosureRuleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureRuleStatus.draft) }
    }
}
