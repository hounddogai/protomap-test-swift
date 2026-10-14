@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultAuthorizationPlanTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDefaultAuthorizationPlan("code-342", name: "name-905")
        #expect(item.status == RevenueCycle.DefaultAuthorizationPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newDefaultAuthorizationPlan("code-342", name: "name-905")
        try item.moveTo(RevenueCycle.DefaultAuthorizationPlanStatus.approved)
        #expect(item.status == RevenueCycle.DefaultAuthorizationPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDefaultAuthorizationPlan("code-342", name: "name-905")
        item.status = RevenueCycle.DefaultAuthorizationPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultAuthorizationPlanStatus.proposed) }
    }
}
