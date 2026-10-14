@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementGroupTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newStatementGroup("code-112", title: "title-966")
        #expect(item.status == RevenueCycle.StatementGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newStatementGroup("code-112", title: "title-966")
        try item.moveTo(RevenueCycle.StatementGroupStatus.withdrawn)
        #expect(item.status == RevenueCycle.StatementGroupStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newStatementGroup("code-112", title: "title-966")
        item.status = RevenueCycle.StatementGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementGroupStatus.proposed) }
    }
}
