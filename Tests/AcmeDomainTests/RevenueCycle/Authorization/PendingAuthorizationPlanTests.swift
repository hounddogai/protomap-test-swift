@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationPlanTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newPendingAuthorizationPlan("code-845", name: "name-83")
        #expect(item.status == RevenueCycle.PendingAuthorizationPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newPendingAuthorizationPlan("code-845", name: "name-83")
        try item.moveTo(RevenueCycle.PendingAuthorizationPlanStatus.granted)
        #expect(item.status == RevenueCycle.PendingAuthorizationPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newPendingAuthorizationPlan("code-845", name: "name-83")
        item.status = RevenueCycle.PendingAuthorizationPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingAuthorizationPlanStatus.requested) }
    }
}
