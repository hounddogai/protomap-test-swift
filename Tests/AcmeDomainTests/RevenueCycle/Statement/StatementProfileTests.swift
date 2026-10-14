@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementProfileTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newStatementProfile("code-854", name: "name-689")
        #expect(item.status == RevenueCycle.StatementProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newStatementProfile("code-854", name: "name-689")
        try item.moveTo(RevenueCycle.StatementProfileStatus.queued)
        #expect(item.status == RevenueCycle.StatementProfileStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newStatementProfile("code-854", name: "name-689")
        item.status = RevenueCycle.StatementProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementProfileStatus.new) }
    }
}
