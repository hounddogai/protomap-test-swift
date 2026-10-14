@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementAuditTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newStatementAudit("code-789", name: "name-271")
        #expect(item.status == RevenueCycle.StatementAuditStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newStatementAudit("code-789", name: "name-271")
        try item.moveTo(RevenueCycle.StatementAuditStatus.published)
        #expect(item.status == RevenueCycle.StatementAuditStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newStatementAudit("code-789", name: "name-271")
        item.status = RevenueCycle.StatementAuditStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementAuditStatus.created) }
    }
}
