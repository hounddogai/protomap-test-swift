@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationMilestoneTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newManualAuthorizationMilestone("code-44", title: "title-808")
        #expect(item.status == RevenueCycle.ManualAuthorizationMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newManualAuthorizationMilestone("code-44", title: "title-808")
        try item.moveTo(RevenueCycle.ManualAuthorizationMilestoneStatus.resolved)
        #expect(item.status == RevenueCycle.ManualAuthorizationMilestoneStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newManualAuthorizationMilestone("code-44", title: "title-808")
        item.status = RevenueCycle.ManualAuthorizationMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualAuthorizationMilestoneStatus.`open`) }
    }
}
