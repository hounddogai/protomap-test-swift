@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementTargetTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newStatementTarget("code-701", name: "name-894")
        #expect(item.status == RevenueCycle.StatementTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newStatementTarget("code-701", name: "name-894")
        try item.moveTo(RevenueCycle.StatementTargetStatus.approved)
        #expect(item.status == RevenueCycle.StatementTargetStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newStatementTarget("code-701", name: "name-894")
        item.status = RevenueCycle.StatementTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementTargetStatus.proposed) }
    }
}
