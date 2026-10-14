@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationEstimateTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newGlobalAuthorizationEstimate("code-63", name: "name-32")
        #expect(item.status == RevenueCycle.GlobalAuthorizationEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newGlobalAuthorizationEstimate("code-63", name: "name-32")
        try item.moveTo(RevenueCycle.GlobalAuthorizationEstimateStatus.approved)
        #expect(item.status == RevenueCycle.GlobalAuthorizationEstimateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newGlobalAuthorizationEstimate("code-63", name: "name-32")
        item.status = RevenueCycle.GlobalAuthorizationEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalAuthorizationEstimateStatus.proposed) }
    }
}
