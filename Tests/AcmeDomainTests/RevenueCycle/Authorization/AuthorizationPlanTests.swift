@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPlanTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationPlan("code-695", label: "label-215")
        #expect(item.status == RevenueCycle.AuthorizationPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newAuthorizationPlan("code-695", label: "label-215")
        try item.moveTo(RevenueCycle.AuthorizationPlanStatus.closed)
        #expect(item.status == RevenueCycle.AuthorizationPlanStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationPlan("code-695", label: "label-215")
        item.status = RevenueCycle.AuthorizationPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationPlanStatus.draft) }
    }
}
