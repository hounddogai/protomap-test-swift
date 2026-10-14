@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimEstimateTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newRollingClaimEstimate("code-37", title: "title-68")
        #expect(item.status == RevenueCycle.RollingClaimEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newRollingClaimEstimate("code-37", title: "title-68")
        try item.moveTo(RevenueCycle.RollingClaimEstimateStatus.approved)
        #expect(item.status == RevenueCycle.RollingClaimEstimateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newRollingClaimEstimate("code-37", title: "title-68")
        item.status = RevenueCycle.RollingClaimEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingClaimEstimateStatus.proposed) }
    }
}
