@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementEntryTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStatementEntry("code-410", name: "name-815")
        #expect(item.status == RevenueCycle.StatementEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newStatementEntry("code-410", name: "name-815")
        try item.moveTo(RevenueCycle.StatementEntryStatus.stopped)
        #expect(item.status == RevenueCycle.StatementEntryStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStatementEntry("code-410", name: "name-815")
        item.status = RevenueCycle.StatementEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementEntryStatus.idle) }
    }
}
