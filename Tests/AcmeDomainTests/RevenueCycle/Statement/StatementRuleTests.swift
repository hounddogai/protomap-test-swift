@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementRuleTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newStatementRule("code-266", label: "label-524")
        #expect(item.status == RevenueCycle.StatementRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newStatementRule("code-266", label: "label-524")
        try item.moveTo(RevenueCycle.StatementRuleStatus.queued)
        #expect(item.status == RevenueCycle.StatementRuleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newStatementRule("code-266", label: "label-524")
        item.status = RevenueCycle.StatementRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementRuleStatus.new) }
    }
}
