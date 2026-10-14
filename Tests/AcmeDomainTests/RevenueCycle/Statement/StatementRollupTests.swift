@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementRollupTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newStatementRollup("code-845", title: "title-667")
        #expect(item.status == RevenueCycle.StatementRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newStatementRollup("code-845", title: "title-667")
        try item.moveTo(RevenueCycle.StatementRollupStatus.completed)
        #expect(item.status == RevenueCycle.StatementRollupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newStatementRollup("code-845", title: "title-667")
        item.status = RevenueCycle.StatementRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementRollupStatus.planned) }
    }
}
