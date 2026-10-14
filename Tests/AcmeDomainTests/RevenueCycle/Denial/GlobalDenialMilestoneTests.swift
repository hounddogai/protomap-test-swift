@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalDenialMilestoneTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newGlobalDenialMilestone("code-428", name: "name-717")
        #expect(item.status == RevenueCycle.GlobalDenialMilestoneStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newGlobalDenialMilestone("code-428", name: "name-717")
        try item.moveTo(RevenueCycle.GlobalDenialMilestoneStatus.queued)
        #expect(item.status == RevenueCycle.GlobalDenialMilestoneStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newGlobalDenialMilestone("code-428", name: "name-717")
        item.status = RevenueCycle.GlobalDenialMilestoneStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalDenialMilestoneStatus.new) }
    }
}
