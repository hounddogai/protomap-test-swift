@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementMilestoneTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newStatementMilestone("code-993", name: "name-227")
        #expect(item.status == RevenueCycle.StatementMilestoneStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newStatementMilestone("code-993", name: "name-227")
        try item.moveTo(RevenueCycle.StatementMilestoneStatus.revoked)
        #expect(item.status == RevenueCycle.StatementMilestoneStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newStatementMilestone("code-993", name: "name-227")
        item.status = RevenueCycle.StatementMilestoneStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementMilestoneStatus.requested) }
    }
}
