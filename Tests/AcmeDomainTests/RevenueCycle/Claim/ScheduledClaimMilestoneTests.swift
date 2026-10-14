@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledClaimMilestoneTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newScheduledClaimMilestone("code-975", name: "name-262")
        #expect(item.status == RevenueCycle.ScheduledClaimMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newScheduledClaimMilestone("code-975", name: "name-262")
        try item.moveTo(RevenueCycle.ScheduledClaimMilestoneStatus.pending)
        #expect(item.status == RevenueCycle.ScheduledClaimMilestoneStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newScheduledClaimMilestone("code-975", name: "name-262")
        item.status = RevenueCycle.ScheduledClaimMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledClaimMilestoneStatus.draft) }
    }
}
