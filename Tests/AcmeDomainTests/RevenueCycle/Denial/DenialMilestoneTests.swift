@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialMilestoneTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newDenialMilestone("code-345", name: "name-97")
        #expect(item.status == RevenueCycle.DenialMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newDenialMilestone("code-345", name: "name-97")
        try item.moveTo(RevenueCycle.DenialMilestoneStatus.pending)
        #expect(item.status == RevenueCycle.DenialMilestoneStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newDenialMilestone("code-345", name: "name-97")
        item.status = RevenueCycle.DenialMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialMilestoneStatus.draft) }
    }
}
