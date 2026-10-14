@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimMilestoneTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newClaimMilestone("code-997", name: "name-250")
        #expect(item.status == RevenueCycle.ClaimMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newClaimMilestone("code-997", name: "name-250")
        try item.moveTo(RevenueCycle.ClaimMilestoneStatus.published)
        #expect(item.status == RevenueCycle.ClaimMilestoneStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newClaimMilestone("code-997", name: "name-250")
        item.status = RevenueCycle.ClaimMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimMilestoneStatus.created) }
    }
}
