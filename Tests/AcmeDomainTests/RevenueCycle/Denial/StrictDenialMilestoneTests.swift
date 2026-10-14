@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictDenialMilestoneTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newStrictDenialMilestone("code-301", title: "title-922")
        #expect(item.status == RevenueCycle.StrictDenialMilestoneStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newStrictDenialMilestone("code-301", title: "title-922")
        try item.moveTo(RevenueCycle.StrictDenialMilestoneStatus.rejected)
        #expect(item.status == RevenueCycle.StrictDenialMilestoneStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newStrictDenialMilestone("code-301", title: "title-922")
        item.status = RevenueCycle.StrictDenialMilestoneStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StrictDenialMilestoneStatus.proposed) }
    }
}
