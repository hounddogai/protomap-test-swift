@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSnapshotTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newStatementSnapshot("code-362", title: "title-308")
        #expect(item.status == RevenueCycle.StatementSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newStatementSnapshot("code-362", title: "title-308")
        try item.moveTo(RevenueCycle.StatementSnapshotStatus.done)
        #expect(item.status == RevenueCycle.StatementSnapshotStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newStatementSnapshot("code-362", title: "title-308")
        item.status = RevenueCycle.StatementSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementSnapshotStatus.new) }
    }
}
