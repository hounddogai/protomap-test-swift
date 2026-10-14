@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledAuthorizationMilestoneTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newScheduledAuthorizationMilestone("code-755", name: "name-887")
        #expect(item.status == RevenueCycle.ScheduledAuthorizationMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newScheduledAuthorizationMilestone("code-755", name: "name-887")
        try item.moveTo(RevenueCycle.ScheduledAuthorizationMilestoneStatus.queued)
        #expect(item.status == RevenueCycle.ScheduledAuthorizationMilestoneStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newScheduledAuthorizationMilestone("code-755", name: "name-887")
        item.status = RevenueCycle.ScheduledAuthorizationMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledAuthorizationMilestoneStatus.new) }
    }
}
