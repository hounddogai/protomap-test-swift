@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementSnapshotTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newCappedStatementSnapshot("code-247", title: "title-878")
        #expect(item.status == RevenueCycle.CappedStatementSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newCappedStatementSnapshot("code-247", title: "title-878")
        try item.moveTo(RevenueCycle.CappedStatementSnapshotStatus.reopened)
        #expect(item.status == RevenueCycle.CappedStatementSnapshotStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newCappedStatementSnapshot("code-247", title: "title-878")
        item.status = RevenueCycle.CappedStatementSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedStatementSnapshotStatus.`open`) }
    }
}
