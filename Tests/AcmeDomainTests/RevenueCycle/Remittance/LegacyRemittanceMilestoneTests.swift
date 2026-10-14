@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyRemittanceMilestoneTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newLegacyRemittanceMilestone("code-436", name: "name-576")
        #expect(item.status == RevenueCycle.LegacyRemittanceMilestoneStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newLegacyRemittanceMilestone("code-436", name: "name-576")
        try item.moveTo(RevenueCycle.LegacyRemittanceMilestoneStatus.closed)
        #expect(item.status == RevenueCycle.LegacyRemittanceMilestoneStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newLegacyRemittanceMilestone("code-436", name: "name-576")
        item.status = RevenueCycle.LegacyRemittanceMilestoneStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyRemittanceMilestoneStatus.draft) }
    }
}
