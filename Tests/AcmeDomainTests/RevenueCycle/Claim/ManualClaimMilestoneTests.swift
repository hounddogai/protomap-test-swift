@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualClaimMilestoneTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newManualClaimMilestone("code-9", name: "name-291")
        #expect(item.status == RevenueCycle.ManualClaimMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newManualClaimMilestone("code-9", name: "name-291")
        try item.moveTo(RevenueCycle.ManualClaimMilestoneStatus.retired)
        #expect(item.status == RevenueCycle.ManualClaimMilestoneStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newManualClaimMilestone("code-9", name: "name-291")
        item.status = RevenueCycle.ManualClaimMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualClaimMilestoneStatus.created) }
    }
}
