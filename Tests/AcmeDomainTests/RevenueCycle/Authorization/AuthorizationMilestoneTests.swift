@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationMilestoneTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newAuthorizationMilestone("code-998", title: "title-366")
        #expect(item.status == RevenueCycle.AuthorizationMilestoneStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newAuthorizationMilestone("code-998", title: "title-366")
        try item.moveTo(RevenueCycle.AuthorizationMilestoneStatus.warming)
        #expect(item.status == RevenueCycle.AuthorizationMilestoneStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newAuthorizationMilestone("code-998", title: "title-366")
        item.status = RevenueCycle.AuthorizationMilestoneStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationMilestoneStatus.idle) }
    }
}
