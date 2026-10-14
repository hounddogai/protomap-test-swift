@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementBundleTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newStatementBundle("code-12", name: "name-828")
        #expect(item.status == RevenueCycle.StatementBundleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newStatementBundle("code-12", name: "name-828")
        try item.moveTo(RevenueCycle.StatementBundleStatus.resolved)
        #expect(item.status == RevenueCycle.StatementBundleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newStatementBundle("code-12", name: "name-828")
        item.status = RevenueCycle.StatementBundleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementBundleStatus.`open`) }
    }
}
