@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newRemittanceMilestone("code-500", title: "title-970")
        #expect(item.status == RevenueCycle.RemittanceMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newRemittanceMilestone("code-500", title: "title-970")
        try item.moveTo(RevenueCycle.RemittanceMilestoneStatus.cancelled)
        #expect(item.status == RevenueCycle.RemittanceMilestoneStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newRemittanceMilestone("code-500", title: "title-970")
        item.status = RevenueCycle.RemittanceMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceMilestoneStatus.planned) }
    }
}
